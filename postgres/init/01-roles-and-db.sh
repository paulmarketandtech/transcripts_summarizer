#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v owner_pw="$SUMMARIZER_OWNER_PASSWORD" \
     -v app_pw="$SUMMARIZER_APP_PASSWORD" \
     -v ro_pw="$SUMMARIZER_READONLY_PASSWORD" <<'SQL'

-- 1. Roles (no superuser, no createdb, no createrole by default)
CREATE ROLE summarizer_owner    LOGIN PASSWORD :'owner_pw';
CREATE ROLE summarizer_app      LOGIN PASSWORD :'app_pw';
CREATE ROLE summarizer_readonly LOGIN PASSWORD :'ro_pw';

-- Guard rails for the app role
ALTER ROLE summarizer_app CONNECTION LIMIT 20;
ALTER ROLE summarizer_app SET statement_timeout = '60s';
ALTER ROLE summarizer_app SET idle_in_transaction_session_timeout = '60s';

-- 2. Database, owned by the migration role
CREATE DATABASE summarizer OWNER summarizer_owner;

-- By default every role may connect to every database. Close that door.
REVOKE ALL ON DATABASE summarizer FROM PUBLIC;
GRANT CONNECT ON DATABASE summarizer TO summarizer_app, summarizer_readonly;

-- 3. Inside the new database
\connect summarizer

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO summarizer_app, summarizer_readonly;

-- Tables the owner creates in the future (via migrations) get these grants automatically
ALTER DEFAULT PRIVILEGES FOR ROLE summarizer_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO summarizer_app;
ALTER DEFAULT PRIVILEGES FOR ROLE summarizer_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO summarizer_app;
ALTER DEFAULT PRIVILEGES FOR ROLE summarizer_owner IN SCHEMA public
  GRANT SELECT ON TABLES TO summarizer_readonly;
SQL
