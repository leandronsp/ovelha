require 'redis'

class PaymentJob
  def initialize
    @redis = Redis.new(host: 'redis')
  end

  def enqueue(correlation_id:, amount:)
    @redis.lpush("payments_queue", {
      correlationId: correlation_id,
      amount: amount
    }.to_json)
  end
end
