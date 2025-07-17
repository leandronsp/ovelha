require 'json'
require 'net/http'
require 'uri'

require_relative 'store'

class Handler 
  VALIDATION_ERRORS = [].freeze

  def self.call(*args)
    new(*args).handle
  end

  def initialize(client)
    @client = client
  end

  def handle
    begin
      ########## Request ##########
      #############################
      message = ''
      headers = {}
      params = {}

      if (line = @client.gets)
        message += line

        headline_regex = /^(GET|POST)\s+([^\s]+)\s+HTTP.*?$/
        verb, path = line.match(headline_regex).captures
        request = "#{verb} #{path}"
      end

      puts "\n[#{Time.now}] #{message}"

      while (line = @client.gets)
        break if line == "\r\n"

        header, value = line.split(': ')
        headers[header] = value.chomp

        message += line
      end

      if headers['Content-Length']
        body_size = headers['Content-Length'].to_i
        body = @client.read(body_size)

        params.merge!(JSON.parse(body))
      end

      ########## Response ##########
      ##############################

      status = nil
      body = '{}'

      case request
        in "POST /payments"
          uri = URI("http://payment-processor-default:8080/payments")

          payload = {
            correlationId: params['correlationId'],
            amount: params['amount'],
            requestedAt: Time.now.utc.iso8601(3)
          }

          http = Net::HTTP.new(uri.host, uri.port)
          req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
          req.body = payload.to_json
          res = http.request(req)

          if res.is_a?(Net::HTTPSuccess)
            Store.new.save(processor: 'default', amount: params['amount'])
            status = 200
            body = { message: 'processed' }.to_json
          else
            status = res.code.to_i
            body = { error: 'failed to process payment' }.to_json
          end
      in "GET /payments-summary"
        summary = Store.new.summary

        status = 200
        body = summary.to_json
      else 
        status = 404
      end
    rescue *VALIDATION_ERRORS => err
      status = 422
      body = { error: err.message }.to_json
    end
    
    response = <<~HTTP
      HTTP/2.0 #{status}
      Content-Type: application/json

      #{body}
    HTTP

    @client.puts(response)
  end
end
