# frozen_string_literal: true

require 'uri'
require 'net/http'

class AddressService < ApplicationService
  API_URL = ENV['ADDRESS_API_URL'].freeze

  def initialize(postcode)
    @postcode = postcode
  end

  def call
    response = make_api_request
    handle_response(response)
  end

  private

  def make_api_request
    uri = URI(API_URL)
    uri.query = URI.encode_www_form(postcode: @postcode, token: ENV['ADDRESS_API_TOKEN'])

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(uri)

    https.request(request)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      parse_address_data(response)
    else
      log_error_response(response)
    end
  end

  def parse_address_data(response)
    addresses = []
    response_data = JSON.parse(response.read_body)
    response_data['data'].map { |obj| addresses << build_complete_address(obj) }
    addresses
  end

  def build_complete_address(address)
    "#{address['_buildingnumber']} #{address['_street']}, #{address['_city']}, #{address['_county']}, #{address['_postcode']}, #{address['p_country']}"
  end

  def log_error_response(response)
    Rails.logger.error("Error: #{response.code} - #{response.message}")
  end
end
