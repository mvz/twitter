require 'http/parser'
require 'openssl'
require 'resolv'

module Twitter
  module Streaming
    class Connection
      attr_reader :tcp_socket_class, :ssl_socket_class, :state

      def initialize(options = {})
        @tcp_socket_class = options.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = options.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
        @using_ssl        = options.fetch(:using_ssl)        { false }
      end

      # Initiate a socket connection and setup response handling
      def stream(request, response)
        client = connect(request)
        request.stream(client)
        while body = client.readpartial(1024) # rubocop:disable AssignmentInCondition
          response << body
        end
      end

      def connect(request)
        port           = request.socket_port || Addressable::URI::PORT_MAPPING[request.uri.scheme]
        client = new_tcp_socket(request.socket_host, request.socket_port)
        return client if !@using_ssl && request.using_proxy?

        client_context = OpenSSL::SSL::SSLContext.new
        ssl_client     = @ssl_socket_class.new(client, client_context)
        ssl_client.connect
      end

    private

      def new_tcp_socket(host, port)
        @tcp_socket_class.new(Resolv.getaddress(host), port)
      end

      # Close the connection when it's in a closeable state
      def close
        return unless closeable?

        transition(:closing, :closed) do
          @ssl_client.close
        end
      end

    private

      def connected?
        @state == :connected
      end

      def connecting?
        @state == :connecting
      end

      def closeable?
        connected? || connecting?
      end

      def transition(from, to)
        @state = from
        yield
        @state = to
      end
    end
  end
end
