require 'redis'

class Store
  def initialize
    @redis = Redis.new(host: 'redis')
  end

  def save(processor:, amount:)
    @redis.incr("totalRequests:#{processor}")
    @redis.incrbyfloat("totalAmount:#{processor}", amount)
  end

  def summary
    %w[default fallback].each_with_object({}) do |type, hash|
      hash[type] = {
        totalRequests: @redis.get("totalRequests:#{type}").to_i,
        totalAmount: @redis.get("totalAmount:#{type}").to_f
      }
    end
  end
end
