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

      uri = URI("http://payment-processor-default:8080/payments")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')

      req.body = payload.merge({
        requestedAt: Time.now.utc.iso8601(3)
      }).to_json

      res = http.request(req)

      if res.is_a?(Net::HTTPSuccess)
        Store.new.save(processor: 'default', amount: payload['amount'])
      else
        puts "Error processing payment: #{res.body}"
      end
    end
  end
end
