-- init.sql
-- Initialize PostgreSQL database with Apache AGE, PGvector, PGAudit, and pgsodium extensions

-- Create extensions
CREATE EXTENSION IF NOT EXISTS age;
-- CREATE EXTENSION IF NOT EXISTS vector; --vectorscale automatically installed vector
CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;
CREATE EXTENSION IF NOT EXISTS vectors;
CREATE EXTENSION IF NOT EXISTS pgaudit;
-- CREATE EXTENSION IF NOT EXISTS pgsodium;

-- Create database
-- CREATE DATABASE postgres;
-- -- Grant permissions to the postgres user
-- GRANT ALL PRIVILEGES ON DATABASE postgres TO postgres;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;