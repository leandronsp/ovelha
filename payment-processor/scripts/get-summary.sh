#!/bin/sh 

echo "Summary of payments (default):"

curl -X GET \
  -H "X-Rinha-Token: 123" \
  http://localhost:8001/admin/payments-summary

echo "\n\n"

echo "Summary of payments (fallback):"

curl -X GET \
  -H "X-Rinha-Token: 123" \
  http://localhost:8002/admin/payments-summary
