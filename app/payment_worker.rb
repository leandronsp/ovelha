require 'redis'
require 'json'
require 'uri'
require 'net/http'

require_relative 'store'

class PaymentWorker
  def initialize
    @redis = Redis.new(host: 'redis')
  end

  def run
    loop do
      puts "Waiting for jobs..."
      _, result = @redis.brpop("payments_queue")

      payload = JSON.parse(result)
      puts "Processing job with payload: #{payload}"

      process_payment(payload)
    rescue Socket::ResolutionError => e
      puts "An error occurred: #{e.message}"
    end
  end

  private

  def process_payment(payload)
    success = try_processor('default', payload)
    return if success

    success = try_processor('fallback', payload)
    return if success

    handle_retry_or_dlq(payload)
  end

  def try_processor(processor_name, payload)
    endpoint = "http://payment-processor-#{processor_name}:8080/payments"
    res = make_request(endpoint, payload)

    case res
    when Net::HTTPSuccess
      Store.new.save(processor: processor_name, amount: payload['amount'])
      true
    when Net::HTTPClientError
      puts "Error processing payment: [#{res.code}] #{res.body}"
      false
    when Net::HTTPServerError
      puts "Error processing payment: [#{res.code}] #{res.body}"
      false
    else
      puts "Unknown error processing payment: [#{res.code}] #{res.body}"
      false
    end
  end

  def handle_retry_or_dlq(payload)
    correlation_id = payload['correlationId']
    retries = @redis.get("retries:#{correlation_id}").to_i

    if retries < 3
      @redis.lpush("payments_queue", payload.to_json)
      @redis.set("retries:#{correlation_id}", retries + 1)
      puts "Retrying payment #{correlation_id} (attempt #{retries + 1})"
    else
      @redis.del("retries:#{correlation_id}")
      @redis.lpush("payments_dlq", payload.to_json)
      puts "Max retries reached for #{correlation_id}, sending to DLQ"
    end
  end

  def make_request(endpoint, payload)
    uri = URI(endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')

    req.body = payload.merge({
      requestedAt: Time.now.utc.iso8601(3)
    }).to_json

    http.request(req)
  end
end
