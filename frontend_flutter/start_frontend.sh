#!/bin/bash
# ------------------------------------------------------------------
# AquaSertão Frontend Startup Script
# 
# Serves the production Flutter Web bundle statically.
# ------------------------------------------------------------------

cd "$(dirname "$0")"

if [ ! -d "build/web" ]; then
    echo "🚀 Building AquaSertão Web Production Bundle..."
    flutter build web --release
fi

echo "👉 Serving AquaSertão Frontend on http://localhost:8082..."
python3 -m http.server 8082 --directory build/web
