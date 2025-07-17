#!/bin/sh 

echo "Default processor health check:"
curl -X GET \
  http://localhost:8001/payments/service-health

echo "\n\n"

echo "Fallback processor health check:"

curl -X GET \
  http://localhost:8002/payments/service-health
