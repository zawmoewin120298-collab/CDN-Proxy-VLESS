#!/bin/bash

# Sing-Box Engine ကို JSON Config ဖြင့် တိုက်ရိုက် စတင်မောင်းနှင်ပါသည်
if [ -f "/etc/sing-box/config.json" ]; then
    echo "🚀 Starting Sing-Box Engine on Port 8080 (Direct Mode)..."
    sing-box run -c /etc/sing-box/config.json
else
    echo "⚠️ ERROR: /etc/sing-box/config.json not found!"
    exit 1
fi
