#!/bin/sh 

echo "Purging payments from default..."

curl -X POST \
  -H "X-Rinha-Token: 123" \
  http://localhost:8001/admin/purge-payments

echo "\n\n"
echo "Purging payments from fallback..."

curl -X POST \
  -H "X-Rinha-Token: 123" \
  http://localhost:8002/admin/purge-payments
