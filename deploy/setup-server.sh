#!/bin/bash
# =============================================================================
# DoJRP GIS — Hetzner Server Setup
# Run this on a fresh Ubuntu 24.04 VPS via SSH
# Usage: ssh root@YOUR_SERVER_IP 'bash -s' < deploy/setup-server.sh
# =============================================================================

set -euo pipefail

echo "=== DoJRP GIS Server Setup ==="

# --- 1. System updates ---
echo "[1/6] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# --- 2. Install PostgreSQL 16 + PostGIS 3 ---
echo "[2/6] Installing PostgreSQL + PostGIS..."
apt-get install -y -qq postgresql postgresql-contrib postgis postgresql-16-postgis-3

# --- 3. Create database and user ---
echo "[3/6] Creating database and GIS user..."

# Generate a random password for the gis user
GIS_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)

sudo -u postgres psql -q <<SQL
-- Create a dedicated user (not superuser)
CREATE USER gisuser WITH PASSWORD '${GIS_PASSWORD}';

-- Create the database
CREATE DATABASE gisdb OWNER gisuser;

-- Connect to gisdb and enable PostGIS
\c gisdb
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Create schemas matching local structure
CREATE SCHEMA IF NOT EXISTS address;
CREATE SCHEMA IF NOT EXISTS fire;
CREATE SCHEMA IF NOT EXISTS incidents;
CREATE SCHEMA IF NOT EXISTS map;
CREATE SCHEMA IF NOT EXISTS police;
CREATE SCHEMA IF NOT EXISTS street;

-- Grant permissions
GRANT ALL ON SCHEMA address, fire, incidents, map, police, street TO gisuser;
GRANT ALL ON ALL TABLES IN SCHEMA address, fire, incidents, map, police, street TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA address GRANT ALL ON TABLES TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA fire GRANT ALL ON TABLES TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA incidents GRANT ALL ON TABLES TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA map GRANT ALL ON TABLES TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA police GRANT ALL ON TABLES TO gisuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA street GRANT ALL ON TABLES TO gisuser;

-- Also grant on public schema for spatial_ref_sys etc.
GRANT USAGE ON SCHEMA public TO gisuser;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO gisuser;
SQL

# --- 4. Configure PostgreSQL for remote access ---
echo "[4/6] Configuring remote access..."

PG_CONF="/etc/postgresql/16/main/postgresql.conf"
PG_HBA="/etc/postgresql/16/main/pg_hba.conf"

# Listen on all interfaces
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Allow password auth from any IP (pg_featureserv connects locally, but we need remote for migration)
echo "host    gisdb    gisuser    0.0.0.0/0    scram-sha-256" >> "$PG_HBA"

# --- 5. Firewall setup ---
echo "[5/6] Configuring firewall..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 5432/tcp    # PostgreSQL (restrict to your IP later)
ufw allow 9000/tcp    # pg_featureserv
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw --force enable

# --- 6. Restart PostgreSQL ---
echo "[6/6] Restarting PostgreSQL..."
systemctl restart postgresql

echo ""
echo "============================================="
echo "  Server setup complete!"
echo "============================================="
echo ""
echo "  Database: gisdb"
echo "  User:     gisuser"
echo "  Password: ${GIS_PASSWORD}"
echo "  Port:     5432"
echo ""
echo "  SAVE THIS PASSWORD — it won't be shown again."
echo ""
echo "  Connection string:"
echo "  postgresql://gisuser:${GIS_PASSWORD}@$(hostname -I | awk '{print $1}'):5432/gisdb"
echo ""
echo "  Next: Run migrate-data.sh from your local machine."
echo "============================================="
