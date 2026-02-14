#!/bin/bash
# =============================================================================
# DoJRP GIS — pg_featureserv Setup
# Run this ON the Hetzner server after setup-server.sh and migrate-data.sh
# Usage: ssh root@YOUR_SERVER_IP 'bash -s' < deploy/setup-featureserv.sh
# =============================================================================

set -euo pipefail

echo "=== pg_featureserv Setup ==="

# --- Configuration ---
FEATURESERV_VERSION="1.3.1"
FEATURESERV_URL="https://github.com/CrunchyData/pg_featureserv/releases/download/v${FEATURESERV_VERSION}/pg_featureserv_${FEATURESERV_VERSION}_linux_amd64.tar.gz"
INSTALL_DIR="/opt/pg_featureserv"
CONFIG_FILE="${INSTALL_DIR}/config/pg_featureserv.toml"

# --- 1. Download and install ---
echo "[1/4] Downloading pg_featureserv v${FEATURESERV_VERSION}..."
mkdir -p "$INSTALL_DIR"
cd /tmp
curl -sSL "$FEATURESERV_URL" -o pg_featureserv.tar.gz
tar xzf pg_featureserv.tar.gz -C "$INSTALL_DIR" --strip-components=1
rm pg_featureserv.tar.gz
chmod +x "${INSTALL_DIR}/pg_featureserv"

# --- 2. Create configuration ---
echo "[2/4] Creating configuration..."
mkdir -p "${INSTALL_DIR}/config"

# Prompt for database password
read -s -p "Enter gisuser database password: " DB_PASSWORD
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

cat > "$CONFIG_FILE" <<TOML
# pg_featureserv configuration for DoJRP GIS

[Server]
# Bind to all interfaces
HttpHost = "0.0.0.0"
HttpPort = 9000
# CORS — allow any origin (restrict in production if needed)
CORSOrigins = "*"
# Base URL for links in responses (update with your domain if you get one)
UrlBase = "http://${SERVER_IP}:9000"
# Debug mode off for production
Debug = false

[Database]
# Connect to local PostgreSQL
DbConnection = "postgresql://gisuser:${DB_PASSWORD}@localhost:5432/gisdb"
# Connection pool
DbPoolMaxConns = 10
# Schemas to expose (only GTA V core data)
DbSchemas = ["address", "fire", "incidents", "map", "police", "street"]

[Paging]
# Default and max number of features per request
LimitDefault = 100
LimitMax = 10000

[Metadata]
Title = "DoJRP GTA V GIS API"
Description = "GeoJSON API for DoJRP GTA V roleplay GIS data — streets, jurisdictions, fire districts, police zones, and more."
TOML

echo "  Config written to ${CONFIG_FILE}"

# --- 3. Create systemd service ---
echo "[3/4] Creating systemd service..."

cat > /etc/systemd/system/pg_featureserv.service <<SERVICE
[Unit]
Description=pg_featureserv - PostGIS Feature Server for DoJRP GIS
After=postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
ExecStart=${INSTALL_DIR}/pg_featureserv --config ${CONFIG_FILE}
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ReadOnlyPaths=${INSTALL_DIR}
PrivateTmp=true

[Install]
WantedBy=multi-user.target
SERVICE

# Ensure www-data can read the install directory
chown -R www-data:www-data "$INSTALL_DIR"

systemctl daemon-reload
systemctl enable pg_featureserv
systemctl start pg_featureserv

# --- 4. Verify ---
echo "[4/4] Verifying..."
sleep 2

if systemctl is-active --quiet pg_featureserv; then
    echo ""
    echo "============================================="
    echo "  pg_featureserv is running!"
    echo "============================================="
    echo ""
    echo "  API root:        http://${SERVER_IP}:9000/"
    echo "  Collections:     http://${SERVER_IP}:9000/collections"
    echo "  OpenAPI spec:    http://${SERVER_IP}:9000/api"
    echo ""
    echo "  Example requests:"
    echo "    All tables:     http://${SERVER_IP}:9000/collections.json"
    echo "    Street network: http://${SERVER_IP}:9000/collections/street.street_network/items.json"
    echo "    Jurisdictions:  http://${SERVER_IP}:9000/collections/map.jurisdiction/items.json"
    echo "    Fire boxes:     http://${SERVER_IP}:9000/collections/fire.fire_box/items.json"
    echo "    Bbox query:     http://${SERVER_IP}:9000/collections/street.street_network/items.json?bbox=-118.5,33.7,-118.1,34.1"
    echo ""
    echo "  Logs: journalctl -u pg_featureserv -f"
    echo "============================================="
else
    echo "  pg_featureserv failed to start. Check logs:"
    echo "  journalctl -u pg_featureserv -n 20"
fi
