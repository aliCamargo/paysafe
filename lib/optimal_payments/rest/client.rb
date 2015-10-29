require 'http'

module OptimalPayments
  module REST
    class Client

      API_TEST = 'https://api.test.netbanx.com'
      API_LIVE = 'https://api.netbanx.com'

      HEADERS = {
        'Content-Type'    => 'application/json',
        'User-Agent'      => "OptimalPaymentsRubyGem/#{OptimalPayments::VERSION}",
        'X-Ruby-Version'  => RUBY_VERSION,
        'X-Ruby-Platform' => RUBY_PLATFORM
      }

      attr_accessor :account_number, :api_key, :api_secret, :test_mode
      attr_reader :api_base

      # Initializes a new Client object
      #
      # @param options [Hash]
      # @return [Optimal::REST::Client]
      def initialize(options={})
        @test_mode = true

        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        yield(self) if block_given?

        @api_base = test_mode ? API_TEST : API_LIVE
      end

      # @return [Hash]
      def credentials
        {
          account_number: account_number,
          api_key: api_key,
          api_secret: api_secret
        }
      end

      # @return [Boolean]
      def credentials?
        credentials.values.all?
      end

      def create_profile(merchantCustomerId:, locale:, **args)
        data = {
          merchantCustomerId: merchantCustomerId,
          locale: locale,
          firstName: args[:firstName],
          lastName: args[:lastName],
          email: args[:email],
          card: args[:card]
        }

        response = post(path: "/customervault/v1/profiles", data: data)
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def delete_profile(id:)
        response = delete(path: "/customervault/v1/profiles/#{id}")
        fail_or_return_response_body(response.code, (response.code == 200))
      end

      def get_profile(id:)
        response = get(path: "/customervault/v1/profiles/#{id}")
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def create_address(profile_id:, country:, zip:, **args)
        data = {
          nickName: args[:nickName],
          street: args[:street],
          city: args[:city],
          country: country,
          state: args[:state],
          zip: zip
        }

        response = post(path: "/customervault/v1/profiles/#{profile_id}/addresses", data: data)
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def create_card(profile_id:, number:, month:, year:, **args)
        data = {
          cardNum: number,
          cardExpiry: {
            month: month,
            year: year
          },
          nickName: args[:nickName],
          holderName: args[:holderName],
          merchantRefNum: args[:merchantRefNum],
          billingAddressId: args[:billingAddressId],
          defaultCardIndicator: args[:defaultCardIndicator]
        }.reject { |key, value| value.nil? }

        response = post(path: "/customervault/v1/profiles/#{profile_id}/cards", data: data)
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def delete_card(profile_id:, id:)
        response = delete(path: "/customervault/v1/profiles/#{profile_id}/cards/#{id}")
        fail_or_return_response_body(response.code, (response.code == 200))
      end

      def get_card(profile_id:, id:)
        response = get(path: "/customervault/v1/profiles/#{profile_id}/cards/#{id}")
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def update_card(profile_id:, id:, month:, year:, **args)
        data = {
          cardExpiry: {
            month: month,
            year: year
          },
          nickName: args[:nickName],
          holderName: args[:holderName],
          merchantRefNum: args[:merchantRefNum],
          billingAddressId: args[:billingAddressId],
          defaultCardIndicator: args[:defaultCardIndicator]
        }.reject { |key, value| value.nil? }

        response = put(path: "/customervault/v1/profiles/#{profile_id}/cards/#{id}", data: data)
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      def purchase(amount:, token:, merchantRefNum:, **args)
        data = {
          amount: amount,
          merchantRefNum: merchantRefNum,
          settleWithAuth: true,
          card: {
            paymentToken: token
          }
        }

        response = post(path: "/cardpayments/v1/accounts/#{account_number}/auths", data: data)
        response_body = symbolize_keys!(response.parse)
        fail_or_return_response_body(response.code, response_body)
      end

      private

      def http_client
        HTTP
          .headers(HEADERS)
          .timeout(write: 2, connect: 5, read: 10)
          .basic_auth(user: @api_key, pass: @api_secret)
      end

      def post(path:, data:)
        http_client.post("#{api_base}#{path}", json: data)
      end

      def get(path:)
        http_client.get("#{api_base}#{path}")
      end

      def delete(path:)
        http_client.delete("#{api_base}#{path}")
      end

      def put(path:, data:)
        http_client.put("#{api_base}#{path}", json: data)
      end

      def symbolize_keys!(object)
        if object.is_a?(Array)
          object.each_with_index do |val, index|
            object[index] = symbolize_keys!(val)
          end
        elsif object.is_a?(Hash)
          object.keys.each do |key|
            object[key.to_sym] = symbolize_keys!(object.delete(key))
          end
        end
        object
      end

      def fail_or_return_response_body(code, body)
        if code < 200 || code >= 206
          error = OptimalPayments::Error.error_from_response(body, code)
          fail(error) if error
        end
        body
      end

    end
  end
end