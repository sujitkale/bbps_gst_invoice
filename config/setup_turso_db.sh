#!/bin/bash
# ================================================================
#  GST Invoice Manager — Turso Database Setup Script
#  
#  Run this ONCE to create all tables in your Turso database.
#
#  Prerequisites:
#    - curl (installed on any Mac/Linux/WSL)
#    - Your Turso DB URL and auth token (from turso.tech dashboard)
#
#  Usage:
#    chmod +x setup_turso_db.sh
#    ./setup_turso_db.sh
#
#  Or set env vars first then run:
#    export TURSO_URL="https://your-db-org.turso.io"
#    export TURSO_TOKEN="your-auth-token"
#    ./setup_turso_db.sh
# ================================================================

# ── Get credentials ──────────────────────────────────────────────
if [ -z "$TURSO_URL" ]; then
  echo ""
  echo "  GST Invoice — Turso Database Setup"
  echo "  ==================================="
  echo ""
  echo "  Find these in: turso.tech → your database → Generate Token"
  echo ""
  read -p "  Turso DB URL (e.g. https://gst-inv-myorg.turso.io): " TURSO_URL
fi

if [ -z "$TURSO_TOKEN" ]; then
  read -p "  Turso Auth Token: " TURSO_TOKEN
fi

TURSO_URL="${TURSO_URL%/}"   # strip trailing slash
ENDPOINT="${TURSO_URL}/v2/pipeline"

echo ""
echo "  Connecting to: $TURSO_URL"
echo ""

# ── Helper: run SQL and check result ────────────────────────────
run_sql() {
  local description="$1"
  local sql="$2"
  
  # Escape the SQL for JSON
  local escaped_sql=$(echo "$sql" | python3 -c "
import sys, json
sql = sys.stdin.read().strip()
print(json.dumps(sql))
" 2>/dev/null || echo "\"$sql\"")

  local payload="{\"requests\":[{\"type\":\"execute\",\"stmt\":{\"sql\":$escaped_sql}},{\"type\":\"close\"}]}"
  
  local response=$(curl -s -X POST "$ENDPOINT" \
    -H "Authorization: Bearer $TURSO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")
  
  if echo "$response" | grep -q '"error"'; then
    echo "  ❌  $description"
    echo "      Error: $(echo $response | python3 -c "import sys,json; d=json.load(sys.stdin); print(d)" 2>/dev/null || echo $response)"
    return 1
  else
    echo "  ✅  $description"
    return 0
  fi
}

# ── Test connection first ────────────────────────────────────────
echo "  Testing connection..."
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  "${TURSO_URL}/health" \
  -H "Authorization: Bearer $TURSO_TOKEN")

if [ "$HEALTH" != "200" ]; then
  echo "  ❌  Cannot connect (HTTP $HEALTH). Check your URL and token."
  exit 1
fi
echo "  ✅  Connected successfully!"
echo ""
echo "  Creating tables..."
echo ""

# ── Create all tables ────────────────────────────────────────────

run_sql "config table" "CREATE TABLE IF NOT EXISTS config (
  id INTEGER PRIMARY KEY,
  company_name TEXT,
  gstin TEXT,
  address TEXT,
  contact TEXT,
  email TEXT,
  bank_name TEXT,
  account_no TEXT,
  ifsc TEXT,
  branch TEXT,
  account_type TEXT,
  beneficiary_name TEXT,
  signatory_name TEXT,
  signatory_title TEXT,
  logo_url TEXT,
  state_code TEXT DEFAULT '27'
)"

run_sql "invoices table" "CREATE TABLE IF NOT EXISTS invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_no TEXT UNIQUE,
  invoice_date TEXT,
  po_no TEXT,
  client_name TEXT,
  client_address TEXT,
  client_gstin TEXT,
  supply_type TEXT DEFAULT 'intra',
  notes TEXT,
  status TEXT DEFAULT 'draft',
  created_at TEXT,
  updated_at TEXT
)"

run_sql "line_items table" "CREATE TABLE IF NOT EXISTS line_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER,
  sr_no INTEGER,
  description TEXT,
  hsn_sac TEXT,
  qty REAL,
  unit TEXT,
  rate REAL,
  taxable_value REAL,
  cgst_rate REAL DEFAULT 0,
  cgst_amt REAL DEFAULT 0,
  sgst_rate REAL DEFAULT 0,
  sgst_amt REAL DEFAULT 0,
  igst_rate REAL DEFAULT 0,
  igst_amt REAL DEFAULT 0
)"

run_sql "audit_log table" "CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT,
  action TEXT,
  entity TEXT,
  entity_id INTEGER,
  detail TEXT
)"

# ── Create indexes for performance ──────────────────────────────
echo ""
echo "  Creating indexes..."
echo ""

run_sql "index on line_items.invoice_id" \
  "CREATE INDEX IF NOT EXISTS idx_line_items_invoice_id ON line_items(invoice_id)"

run_sql "index on invoices.invoice_date" \
  "CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date)"

run_sql "index on audit_log.ts" \
  "CREATE INDEX IF NOT EXISTS idx_audit_ts ON audit_log(ts)"

# ── Verify by listing tables ─────────────────────────────────────
echo ""
echo "  Verifying tables..."
echo ""

TABLES_RESPONSE=$(curl -s -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $TURSO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"requests":[{"type":"execute","stmt":{"sql":"SELECT name FROM sqlite_master WHERE type='\''table'\'' ORDER BY name"}},{"type":"close"}]}')

TABLES=$(echo "$TABLES_RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    rows = d['results'][0]['response']['result']['rows']
    for r in rows:
        print('  ✅  Table:', r[0]['value'])
except:
    print('  Could not parse:', sys.stdin.read()[:200])
" 2>/dev/null)

echo "$TABLES"

echo ""
echo "  =============================================="
echo "  ✅  Database setup complete!"
echo "  =============================================="
echo ""
echo "  Next steps:"
echo "  1. Copy your credentials into index.html:"
echo "     TURSO_URL   = $TURSO_URL"
echo "     TURSO_TOKEN = (your token — keep secret!)"
echo ""
echo "  2. Or set them as Netlify environment variables:"
echo "     Site Settings → Environment Variables"
echo "     TURSO_URL and TURSO_TOKEN"
echo ""
echo "  3. Deploy index.html to Netlify"
echo ""
