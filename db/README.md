# Database foundation

The first Liquibase migration creates nine PostgreSQL tables. The master changelog is
`src/main/resources/db/changelog/db.changelog-master.yaml`. It seeds these stable role
codes: `SUPER_ADMIN`, `OPS_LEAD`, `OPS_ADMIN`, and `CLIENT_USER`.

Set `VV_DB_URL`, `VV_DB_USERNAME`, and `VV_DB_PASSWORD` for the application runtime role.
Migrations are disabled by default. Run migrations with `VV_DB_MIGRATIONS_ENABLED=true`
and a separate schema-owner credential supplied through Spring's
`SPRING_LIQUIBASE_URL`, `SPRING_LIQUIBASE_USER`, and `SPRING_LIQUIBASE_PASSWORD`.
Do not give the runtime role schema ownership or DDL privileges.

e