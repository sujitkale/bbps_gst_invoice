# 🇮🇳 GST Invoice Manager

A mobile-friendly GST invoicing web application for Indian businesses.

## Features
- **Company Settings** — One-time setup of GSTIN, address, bank details
- **Invoice Creation** — Yellow fields for input, green for auto-calculated GST
- **Intra / Inter-State** — CGST+SGST or IGST switching
- **Up to 20 line items** per invoice
- **PDF & Excel Export** — Professional formatted output
- **Edit Invoices Retroactively** — Amend any saved invoice
- **Invoice List & Search** — View, search, delete all invoices
- **Dashboard & Reports** — Monthly revenue charts, GST summary

## Quick Start

### 1. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the app
```bash
python run.py
```

This starts both backend (port 5000) and frontend (port 8080).
Open your browser to: **http://localhost:8080**

### First-Time Setup
1. Go to **⚙️ Settings** tab
2. Fill in your company GSTIN, address, bank details
3. Click **Save Settings**
4. Go to **➕ New Invoice** and start billing!

## Deployment (Cloud)

### Option A: Render.com (Free)
1. Push this folder to GitHub
2. Create a new Web Service on render.com
3. Build command: `pip install -r requirements.txt`
4. Start command: `gunicorn app:app`
5. Serve index.html separately via Render Static Site

### Option B: Railway.app
1. Push to GitHub
2. Connect Railway → Deploy → done!

### Option C: PythonAnywhere
1. Upload files
2. Set WSGI to point at `app.py`
3. Done — free hosting!

## Database
Uses SQLite (`gst_invoices.db`) — zero config, stored locally.
For production, swap with PostgreSQL by changing the `get_db()` function.

## File Structure
```
gst-invoice/
├── app.py          # Flask backend API
├── index.html      # Frontend (single-page app)
├── run.py          # Convenience startup script
├── requirements.txt
├── README.md
└── gst_invoices.db # Created on first run
```

## GST Calculation Logic
- **Taxable Value** = Qty × Rate
- **CGST** = Taxable Value × CGST% (for intra-state)
- **SGST** = Taxable Value × SGST% (= CGST for same-state)
- **IGST** = Taxable Value × IGST% (for inter-state)
- **Round Off** = Nearest Rupee
- **Total** = Taxable + CGST + SGST + IGST + Round Off
