import os

# Final environment variable processing - must be at the very end
# to override any config file assignments
ENV_VAR_KEYS = {
    "SUPERSET__SQLALCHEMY_DATABASE_URI",
    "SUPERSET__SQLALCHEMY_EXAMPLES_URI",
}

for env_var in ENV_VAR_KEYS:
    if env_var in os.environ:
        config_var = env_var.replace("SUPERSET__", "")
        globals()[config_var] = os.environ[env_var]