require "net/http"
require "uri"
require_relative "errors/too_many_redirects"

module X
  # Handles HTTP redirects
  class RedirectHandler
    DEFAULT_MAX_REDIRECTS = 10

    attr_accessor :max_redirects
    attr_reader :authenticator, :connection, :request_builder

    def initialize(authenticator:, connection:, request_builder:, max_redirects: DEFAULT_MAX_REDIRECTS)
      @authenticator = authenticator
      @connection = connection
      @request_builder = request_builder
      @max_redirects = max_redirects
    end

    def handle(response:, request:, base_url:, redirect_count: 0)
      if response.is_a?(Net::HTTPRedirection)
        raise TooManyRedirects, "Too many redirects" if redirect_count > max_redirects

        new_uri = build_new_uri(response, base_url)

        new_request = build_request(request, new_uri, Integer(response.code))
        new_response = connection.perform(request: new_request)

        handle(response: new_response, request: new_request, base_url: base_url, redirect_count: redirect_count + 1)
      else
        response
      end
    end

    private

    def build_new_uri(response, base_url)
      location = response.fetch("location")
      # If location is relative, it will join with the original base URL, otherwise it will overwrite it
      URI.join(base_url, location)
    end

    def build_request(request, new_uri, response_code)
      http_method, body = case response_code
      in 307 | 308
        [request.method.downcase.to_sym, request.body]
      else
        [:get, nil]
      end

      request_builder.build(http_method: http_method, uri: new_uri, body: body, authenticator: authenticator)
    end
  end
end
