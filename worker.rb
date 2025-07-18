require_relative 'app/payment_worker'

worker = PaymentWorker.new
worker.run
