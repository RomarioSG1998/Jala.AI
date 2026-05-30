#!/bin/bash
# ------------------------------------------------------------------
# AquaSertão Frontend Startup Script
# 
# Description: Starts the Flutter app in web-server mode.
# Because of snap environment bugs with Linux Desktop builds on Ubuntu,
# we use the web-server to reliably test the application.
# 
# Usage: ./start_frontend.sh
# Then open: http://localhost:8082 in your browser.
# Press F12 -> Ctrl+Shift+M to simulate the mobile experience!
# ------------------------------------------------------------------

echo "🚀 Starting AquaSertão Frontend on Web Server..."
echo "👉 Open http://localhost:8082 in Chrome/Edge."
echo "📱 Remember to press F12 and toggle Device Toolbar for the Cellphone view!"

flutter run -d web-server --web-port 8082
