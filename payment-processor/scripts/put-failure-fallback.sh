#!/bin/sh 

echo "Simulating payment failures to fallback processor..."

curl -v -X PUT \
  -H "X-Rinha-Token: 123" \
  -H "Content-Type: application/json" \
  -d '{ "failure": true }' \
  http://localhost:8002/admin/configurations/failure
