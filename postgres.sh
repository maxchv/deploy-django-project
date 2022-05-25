sudo -u postgres psql<<EOF
CREATE USER dbuser WITH ENCRYPTED PASSWORD 'django';
CREATE DATABASE djangodb WITH OWNER=dbuser;
ALTER ROLE dbuser SET client_encoding TO 'utf8';
ALTER ROLE dbuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE dbuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE djangodb TO dbuser;
EOF
