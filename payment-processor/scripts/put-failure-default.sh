#!/bin/sh 

echo "Simulating payment failures to default processor..."

curl -v -X PUT \
  -H "X-Rinha-Token: 123" \
  -H "Content-Type: application/json" \
  -d '{ "failure": true }' \
  http://localhost:8001/admin/configurations/failure
