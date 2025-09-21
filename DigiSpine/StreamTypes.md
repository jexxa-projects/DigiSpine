# Work in Progress: Stream-Typen & Nutzung

## Übersicht der Stream-Typen

| Stream-Typ                  | Nutzung im Produktionsumfeld                                | Empfohlenes Suffix/Prefix     | Kommentar                                                                 |
|------------------------------|-------------------------------------------------------------|--------------------------------|---------------------------------------------------------------------------|
| **Event Stream**             | Historie, Audit, abgeschlossene Geschäftsprozesse, Roh-Telemetrie | `_events` oder `ev_`           | Append-only; jedes Event zählt, Konsumenten müssen Idempotenz selbst sicherstellen |
| **Upsert / State Stream**    | Aktueller Status, Dashboards, BI                           | `_upsert` oder `st_`           | Jeder Key = aktueller Zustand; Updates überschreiben alte Werte; ideal für MVs |
| **CDC Stream**               | Integration von Legacy-DBs, Synchronisation                | `_cdc`                         | Capture-Change-Data; enthält Insert/Update/Delete; kann Upsert oder Append-only sein |
| **Windowed / Aggregated**    | Reporting, KPIs, Zeitreihen                                | `_agg` oder `_window`          | Aggregationen über Zeitfenster; abgeleitet aus Event- oder Upsert-Streams |
| **Compacted / Keyed Stream** | Konfigurations-/Statuswerte, reduzierte Speicherung        | `_keyed` oder `_compact`       | Kafka kompaktierter Topic; nur letzter Stand pro Key wird gespeichert |
| **Temporal / Event-Time**    | Korrekte Zeitreihenanalyse trotz verzögerter Events        | `_temporal`                    | Event-time basiert; wichtig für verspätete Events; meist kombiniert mit Windowed/Upsert |

---

## Hinweise zur Nutzung

1. **Prefix vs. Suffix**
    - Prefix (`st_`, `ev_`) → schneller Überblick in Topic-Listen / Monitoring.
    - Suffix (`_upsert`, `_events`) → leichter in SQL / Materialized Views zu erkennen.
    - Kombination möglich: `st_fertigung_day_upsert`.

2. **Versionierung**
    - Für Recreate/Blue-Green-Streams → `_v1`, `_v2` ergänzen.

3. **Metadaten im Event**
    - Feld `stream_type` in JSON/Avro hinzufügen → maschinenlesbar & für automatisierte Prozesse nutzbar.

---

## Beispiel-Architektur: Fertigungs-BI-Szenario

### 1️⃣ Event-Historie (Append-only)
- **Topic:** `ev_fertigung_events_v1`
- **Zweck:** Vollständige Historie für Audit, Debugging, Nachverfolgung.
- **Eigenschaft:** Append-only, Updates/Refeeds werden angehängt.
- **Verwendung:** Historische Auswertungen, Trend-Analysen, Replay.

---

### 2️⃣ Upsert-State Stream
- **Topic:** `st_fertigung_day_upsert_v1`
- **Zweck:** Aktueller Stand pro Tag/Anlage → Dashboards, BI.
- **Eigenschaft:** Primary Key (z. B. `produkt_ref`, `schritt_id`), Updates überschreiben.
- **Verwendung:** MVs für Mengen pro Tag/Anlage, konsistente Zahlen im Dashboard.

---

### 3️⃣ CDC Stream
- **Topic:** `ev_fertigung_cdc_v1`
- **Zweck:** Integration von Legacy-DBs.
- **Eigenschaft:** Insert/Update/Delete; je nach Connector Append-only oder Upsert.
- **Verwendung:** MV-Aufbau für aktuelle Produktionsdaten oder Statuswerte.

---

### 4️⃣ Windowed / Aggregated Stream
- **Topic:** `st_fertigung_day_agg_v1`
- **Zweck:** KPI-Berechnung über Zeitfenster (Tagesproduktion, Wochenreports).
- **Eigenschaft:** Abgeleitet aus Upsert- oder Event-Streams.
- **Verwendung:** SUM/COUNT in RisingWave-MVs, direkt für BI nutzbar.

---

### 5️⃣ Compacted / Keyed Stream
- **Topic:** `st_fertigung_config_keyed`
- **Zweck:** Konfigurationen oder selten ändernde Statuswerte.
- **Eigenschaft:** Nur letzter Wert pro Key bleibt erhalten.
- **Verwendung:** Source in RisingWave → MV für aktuelle Konfiguration.

---

### 6️⃣ Temporal / Event-Time Stream
- **Topic:** `ev_fertigung_temporal_v1`
- **Zweck:** Zeitreihenanalyse bei verspäteten/out-of-order Events.
- **Eigenschaft:** Event-time basiert, benötigt Watermarks.
- **Verwendung:** MVs mit Event-Time-Windowing für korrekte KPIs.

---

## Empfehlung Namensschema

- **Prefix:**
    - `st_` → Upsert / State / Aggregation
    - `ev_` → Append-only / Historie / CDC

- **Suffix:**
    - `_upsert`, `_agg`, `_events`, `_keyed`, `_temporal`
    - `_v1`, `_v2` für Versionierung

➡ Beispiel: `st_fertigung_day_upsert_v1`, `ev_fertigung_events_v1`

---

## Vorteile der Architektur

1. **Klare Trennung der Stream-Arten** → weniger Fehler, einfacheres Monitoring.
2. **Dashboards/BI** konsumieren Upsert-Streams → konsistente Kennzahlen.
3. **Historie & Audit** bleibt durch Append-only erhalten → Event-Sourcing möglich.
4. **Aggregationen & KPIs** werden effizient über MVs berechnet.

---

## Quelle vs. Ableitung (Kurzübersicht)

1. **Event Stream (Append-only)**
    - Quelle, Basis für alle anderen.

2. **CDC Stream**
    - Quelle (DB-Änderungen), kann Event/Upsert erzeugen.

3. **Upsert / State Stream**
    - Quelle oder Ableitung (aus Event/CDC).

4. **Compacted / Keyed Stream**
    - Abgeleitet aus Event/Upsert + Kafka-Compaction.

5. **Windowed / Aggregated Stream**
    - Abgeleitet aus Event/Upsert per Zeitfenster.

6. **Temporal / Event-Time**
    - Kein eigener Stream, sondern Verarbeitungsparadigma auf Event/CDC/Upsert.


## Einschränkungen von CDC-Streams

The following limitations arise when using CDC-Streams even in combination with additional such as `debezium`

CDC-Stream enthält DB-Transaktionen und liefert pro Zeile/Row:
- Operationstyp: c (create), u (update), d (delete).
- Before/After-Image: vorheriger und neuer Zustand der Zeile.
- Metadaten: Commit-Zeitstempel, Transaktions-ID, ggf. Schemaänderungen.

👉 Das sind rein technische Änderungsereignisse: „Zeile X in Tabelle Y hat sich geändert“.

⸻

2. Fachliche Events brauchen mehr

Ein fachliches Event hat normalerweise folgende Eigenschaften:
- Namensgebung in der Fachdomäne („ProduktionGestartet“, „BrennvorgangBeendet“) statt „row updated“.
- Aggregierte Information statt einzelner DB-Spaltenänderungen.
- Explizite Semantik (z.B. Statuswechsel „in Produktion → fertig“).
- Stabile ID / Referenz (Geschäftsschlüssel statt technischer PK).

⸻

3. Wo die Grenzen von CDC/Debezium sind

CDC/Debezium kann nicht wissen:
- __Warum__ sich ein Feld geändert hat (nur dass es sich geändert hat).
- Ob mehrere Spaltenänderungen zusammen einen fachlichen Statuswechsel darstellen.
- Ob mehrere Tabellenänderungen zusammengehören (z. B. Bestellung + Positionen).
- Welche Änderungen fachlich irrelevant sind (z. B. Audit-Spalte „last_updated“).

👉 CDC/Debezium ist „lossless“ → es liefert jeden DB-Change, aber ohne Fachlogik.

⸻

4. Wann man eine „Übersetzungsschicht“ braucht

Du stößt in der Praxis an Grenzen, wenn:
1.	Mehrere Tabellen einen fachlichen Vorgang beschreiben.
- Beispiel: Ein Produktionsauftrag wird durch Änderungen in auftrag + auftragsschritte + ressourcen sichtbar.
- Debezium feuert aber 3 getrennte CDC-Events.
2.	Updates ohne fachliche Relevanz existieren.
- Beispiel: Nur ein Timestamp oder ein technischer Counter ändert sich → trotzdem wird ein CDC-Event erzeugt.
3.	„Delta vs. Zustand“ wichtig ist.
- CDC sagt: „Spalte X wurde von 12 → 13 geändert“.
- Fachlich will man: „Menge 1 Stück produziert“.
4.	Fachliche Konsistenz über mehrere Änderungen gewahrt bleiben muss.
- DB macht mehrere Updates innerhalb einer Transaktion → fachlich ist das ein „Event“ (z. B. „Auftrag abgeschlossen“).

⸻

5. Typische Lösungsmuster
   - Event-Hydration Layer:
   - Nimm CDC als Rohinput.
   - Transformiere in einem Streaming-System (z. B. Kafka Streams, Flink, RisingWave) zu fachlichen Events.
   - Mapping-Strategien:
   - CDC-Topic → internes „State Store“ (z. B. Key = Auftrag).
   - Wenn bestimmtes Muster erfüllt ist (z. B. Statusfeld springt von STARTED → DONE), dann emittiere Fach-Event.
   - Filterung:
   - Uninteressante Updates verwerfen (z. B. „last_updated“).
   - Anreicherung:
   - CDC liefert nur den nackten Row-Change.
   - Fachliches Event fügt Kontext hinzu (Produktionslinie, Geschäftsschlüssel, berechnete KPIs).

⸻

6. Faustregel
   - Nur CDC → gut für technische Synchronisation (Replikation, Upsert-State in DWH).
   - CDC + Logikschicht → notwendig für echtes Event-Sourcing / BI / Integration.
   - Ab wann?
   - Sobald ein Update nicht 1:1 als „fachliches Ereignis“ verstanden werden kann, brauchst du Transformation.
   - Spätestens wenn mehrere Tabellen zusammengehören, oder „Delta vs. Business-Event“ auseinanderlaufen.