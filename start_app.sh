#!/bin/bash
cd /opt/xanalyzer/src/
source .venv/bin/activate
pm2 start ecosystem.config.js
