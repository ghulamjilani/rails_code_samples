module Twillio
  class Verify < ::ApplicationService
    attr_reader :client, :receiver_no, :code

    def initialize(receiver_no, code)
      @client = Twilio::REST::Client.new
      @receiver_no = to_international_format(receiver_no)
      @code = code
    end

    def call
      result = client.verify
                     .v2
                     .services(ENV['TWILIO_VERIFY_SID'])
                     .verification_checks
                     .create(to: receiver_no, code: code)

      result.status == 'approved'
    rescue Twilio::REST::RestError => e
      Rails.logger.error("Twilio Verification Error: #{e.message}")
      false
    end
  end
end
