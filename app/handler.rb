require 'json'
require 'net/http'
require 'uri'

require_relative 'store'
require_relative 'payment_job'

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
          PaymentJob.new.enqueue(
            correlation_id: params['correlationId'],
            amount: params['amount']
          )

          status = 200
          body = { message: 'enqueued' }.to_json
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
