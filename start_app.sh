#!/bin/bash
cd /opt/xanalyzer/  # Changed from /opt/xanalyzer/src/
source src/.venv/bin/activate  # Adjusted path to venv
pm2 delete xanalyzer-app || true
pm2 start ecosystem.config.js