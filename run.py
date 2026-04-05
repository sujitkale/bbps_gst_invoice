#!/usr/bin/env python3
"""
GST Invoice Manager - Startup Script
Run: python run.py
Then open: http://localhost:8080
"""
import subprocess, sys, os, threading, webbrowser, time

def start_backend():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    subprocess.run([sys.executable, 'app.py'])

def start_frontend():
    import http.server, socketserver
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *args): pass
    with socketserver.TCPServer(('0.0.0.0', 8080), Handler) as httpd:
        print("🌐 Frontend running at: http://localhost:8080")
        httpd.serve_forever()

def open_browser():
    time.sleep(2)
    webbrowser.open('http://localhost:8080')

print("🚀 Starting GST Invoice Manager...")
print("📊 Backend API: http://localhost:5000")
print("🌐 Web App:     http://localhost:8080")

t1 = threading.Thread(target=start_backend, daemon=True)
t2 = threading.Thread(target=start_frontend, daemon=True)
t3 = threading.Thread(target=open_browser, daemon=True)

t1.start()
time.sleep(1)
t2.start()
t3.start()

try:
    t1.join()
except KeyboardInterrupt:
    print("\n✋ Stopped.")
