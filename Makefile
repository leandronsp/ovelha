payment-processor.up: # Start the payment processor service
	docker compose -f payment-processor/docker-compose.yml up -d
