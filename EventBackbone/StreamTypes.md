# Work in Progress: Stream Types & Usage

## Overview of Stream Types


| Stream Type | Production Usage | Recommended Suffix/Prefix | Comment |
|:---|:---|:---|:---|
| **Event Stream** | History, audit, completed business processes, raw telemetry | `_events` or `ev_` | Append-only; every event counts; consumers must ensure idempotency themselves |
| **Upsert / State Stream** | Current status, dashboards, BI | `_upsert` or `st_` | Each key = current state; updates overwrite old values; ideal for MVs |
| **CDC Stream** | Legacy DB integration, synchronization | `_cdc` | Change Data Capture; contains Insert/Update/Delete; can be Upsert or Append-only |
| **Windowed / Aggregated** | Reporting, KPIs, time series | `_agg` or `_window` | Aggregations over time windows; derived from Event or Upsert streams |
| **Compacted / Keyed Stream** | Configuration/status values, reduced storage | `_keyed` or `_compact` | Kafka compacted topic; only the latest state per key is stored |
| **Temporal / Event-Time** | Correct time-series analysis despite delayed events | `_temporal` | Event-time based; critical for late-arriving events; usually combined with Windowed/Upsert |

---

## Usage Guidelines

1. **Prefix vs. Suffix**
   - **Prefix** (`st_`, `ev_`) → Quick overview in topic lists / monitoring.
   - **Suffix** (`_upsert`, `_events`) → Easier to identify in SQL / Materialized Views.
   - **Combination possible:** e.g., `st_manufacturing_day_upsert`.

2. **Versioning**
   - For Recreate/Blue-Green streams → append `_v1`, `_v2`, etc.

3. **Event Metadata**
   - Add a `stream_type` field in JSON/Avro → machine-readable & usable for automated processes.

---

## Example Architecture: Manufacturing BI Scenario

### 1️⃣ Event History (Append-only)
- **Topic:** `ev_manufacturing_events_v1`
- **Purpose:** Full history for audit, debugging, and tracking.
- **Properties:** Append-only; updates/re-feeds are appended.
- **Usage:** Historical analysis, trend analysis, replay.

---

### 2️⃣ Upsert-State Stream
- **Topic:** `st_manufacturing_day_upsert_v1`
- **Purpose:** Current status per day/facility → Dashboards, BI.
- **Properties:** Primary Key (e.g., `product_ref`, `step_id`); updates overwrite old data.
- **Usage:** MVs for quantities per day/facility, consistent numbers in dashboards.

---

### 3️⃣ CDC Stream
- **Topic:** `ev_manufacturing_cdc_v1`
- **Purpose:** Integration of legacy databases.
- **Properties:** Insert/Update/Delete; append-only or upsert depending on the connector.
- **Usage:** Building MVs for current production data or status values.

---

### 4️⃣ Windowed / Aggregated Stream
- **Topic:** `st_manufacturing_day_agg_v1`
- **Purpose:** KPI calculation over time windows (daily production, weekly reports).
- **Properties:** Derived from Upsert or Event streams.
- **Usage:** SUM/COUNT in RisingWave MVs, directly usable for BI.

---

### 5️⃣ Compacted / Keyed Stream
- **Topic:** `st_manufacturing_config_keyed`
- **Purpose:** Configurations or rarely changing status values.
- **Properties:** Only the latest value per key is retained.
- **Usage:** Source in RisingWave → MV for current configuration.

---

### 6️⃣ Temporal / Event-Time Stream
- **Topic:** `ev_manufacturing_temporal_v1`
- **Purpose:** Time-series analysis for delayed/out-of-order events.
- **Properties:** Event-time based, requires watermarks.
- **Usage:** MVs with event-time windowing for correct KPIs.

---

## Recommended Naming Convention

- **Prefix:**
   - `st_` → Upsert / State / Aggregation
   - `ev_` → Append-only / History / CDC

- **Suffix:**
   - `_upsert`, `_agg`, `_events`, `_keyed`, `_temporal`
   - `_v1`, `_v2` for versioning

➡ **Example:** `st_manufacturing_day_upsert_v1`, `ev_manufacturing_events_v1`

---

## Advantages of the Architecture

1. **Clear separation of stream types** → fewer errors, easier monitoring.
2. **Dashboards/BI** consume Upsert streams → consistent key figures.
3. **History & Audit** are preserved via Append-only → enables Event Sourcing.
4. **Aggregationen & KPIs** are calculated efficiently via MVs.

---

## Source vs. Derived (Quick Overview)

1. **Event Stream (Append-only)**
   - Source; the foundation for all others.
2. **CDC Stream**
   - Source (DB changes); can generate Event or Upsert streams.
3. **Upsert / State Stream**
   - Source or derived (from Event/CDC).
4. **Compacted / Keyed Stream**
   - Derived from Event/Upsert + Kafka Compaction.
5. **Windowed / Aggregated Stream**
   - Derived from Event/Upsert via time windows.
6. **Temporal / Event-Time**
   - Not a standalone stream, but a processing paradigm applied to Event/CDC/Upsert.

---

## Limitations of CDC Streams

The following limitations arise when using CDC streams, even in combination with tools like `Debezium`:

1. **Technical vs. Business perspective**
   A CDC stream contains DB transactions and provides per row:
   - Operation type: c (create), u (update), d (delete).
   - Before/After image: previous and new state of the row.
   - Metadata: commit timestamp, transaction ID, schema changes.

   👉 These are purely technical change events: "Row X in Table Y has changed."

2. **Business events require more**
   A business event typically has the following properties:
   - Domain-driven naming ("ProductionStarted", "FiringProcessFinished") instead of "row updated".
   - Aggregated information instead of individual column changes.
   - Explicit semantics (e.g., status change "In Production → Finished").
   - Stable ID / Reference (Business key instead of technical PK).

3. **Where CDC/Debezium hits its limits**
   CDC/Debezium cannot know:
   - **Why** a field changed (only that it did).
   - If multiple column changes together represent a business status change.
   - If changes in multiple tables belong together (e.g., Order + Line Items).
   - Which changes are business-irrelevant (e.g., "last_updated" audit column).

   👉 CDC/Debezium is "lossless" → it delivers every DB change, but without business logic.

4. **When you need a "Translation Layer"**
   You will hit practical limits when:
   - **Multiple tables describe one business process:** An order becomes visible through changes in `orders` + `order_steps` + `resources`. Debezium fires 3 separate CDC events.
   - **Updates without business relevance exist:** If only a technical counter changes, a CDC event is still generated.
   - **"Delta vs. State" is important:** CDC says "Column X changed from 12 to 13." Business-wise, you want "1 unit produced."
   - **Business consistency must be maintained across multiple changes:** A DB performs multiple updates within one transaction → business-wise, this is one "event" (e.g., "Order Completed").

5. **Typical Solution Patterns**
   - **Event Hydration Layer:** Take CDC as raw input and transform it in a streaming system (e.g., Kafka Streams, Flink, RisingWave) into business events.
   - **Mapping Strategies:** Use a CDC topic as an internal "State Store" (e.g., Key = Order). When a specific pattern is met (e.g., status field jumps from STARTED to DONE), then emit a Business Event.
   - **Filtering:** Discard uninteresting updates (e.g., "last_updated").
   - **Enrichment:** CDC provides only the raw row change. A business event adds context (production line, business keys, calculated KPIs).

6. **Rule of Thumb**
   - **Only CDC** → Good for technical synchronization (replication, upsert-state in DWH).
   - **CDC + Logic Layer** → Necessary for true Event Sourcing / BI / Intelligent Alerting.
