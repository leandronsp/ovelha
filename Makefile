payment-processor.up: # Start the payment processor service
	docker compose -f payment-processor/docker-compose.yml up -d

payment-processor.logs: # View logs for the payment processor service
	docker compose -f payment-processor/docker-compose.yml logs -f
