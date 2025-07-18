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

      res = make_request("http://payment-processor-default:8080/payments", payload)

      if res.is_a?(Net::HTTPSuccess)
        Store.new.save(processor: 'default', amount: payload['amount'])
      elsif res.is_a?(Net::HTTPClientError) # 4xx
        puts "Error processing payment: [#{res.code}] #{res.body}"
      elsif res.is_a?(Net::HTTPServerError) # 5xx
        puts "Error processing payment: [#{res.code}] #{res.body}"

        res = make_request("http://payment-processor-fallback:8080/payments", payload)

        if res.is_a?(Net::HTTPSuccess)
          Store.new.save(processor: 'fallback', amount: payload['amount'])
        elsif res.is_a?(Net::HTTPClientError) # 4xx
          puts "Error processing payment: [#{res.code}] #{res.body}"
        elsif res.is_a?(Net::HTTPServerError) # 5xx
          puts "Error processing payment: [#{res.code}] #{res.body}"
          @redis.lpush("payments_queue", payload.to_json)
        else
          puts "Unkonwn error processing payment: [#{res.code}] #{res.body}"
        end
      else
        puts "Unkonwn error processing payment: [#{res.code}] #{res.body}"
      end
    rescue Socket::ResolutionError => e
      puts "An error occurred: #{e.message}"
      # fallback
    end
  end

  private

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
