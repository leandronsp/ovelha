#!/bin/sh 

echo "Posting payment to default..."
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"correlationId\": \"$uuid\",
    \"amount\": 10.00,
    \"requestedAt\": \"$timestamp\"
  }" \
  http://localhost:8001/payments

echo "\n\n"
echo "Posting payment to fallback..."
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

curl -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"correlationId\": \"$uuid\",
    \"amount\": 10.00,
    \"requestedAt\": \"$timestamp\"
  }" \
  http://localhost:8002/payments
