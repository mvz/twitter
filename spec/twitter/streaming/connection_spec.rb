require 'helper'

class FakeSSLSocket
  def initialize(_, _); end

  def connect; end

  def <<(_); end

  def readpartial(_); end

  def close; end
end

describe Twitter::Streaming::Connection do
  let(:request) do
    HTTP::Request.new(:post, 'https://stream.twitter.com:443/1.1/statuses/filter.json')
  end

  describe 'initialize' do
    context 'no options provided' do
      subject(:connection) { Twitter::Streaming::Connection.new }

      it 'sets the default socket classes' do
        expect(connection.tcp_socket_class).to eq TCPSocket
        expect(connection.ssl_socket_class).to eq OpenSSL::SSL::SSLSocket
      end
    end

    context 'custom socket classes provided in opts' do
      class DummyTCPSocket; end
      class DummySSLSocket; end

      subject(:connection) do
        Twitter::Streaming::Connection.new(tcp_socket_class: DummyTCPSocket, ssl_socket_class: DummySSLSocket)
      end

      it 'sets the default socket classes' do
        expect(connection.tcp_socket_class).to eq DummyTCPSocket
        expect(connection.ssl_socket_class).to eq DummySSLSocket
      end
    end

    it 'initializes the connection state' do
      expect(subject.state).to eq :initialized
    end
  end

  describe '#stream' do
    subject(:connection) do
      Twitter::Streaming::Connection.new(ssl_socket_class: FakeSSLSocket)
    end

    it 'sets the state to connected' do
      connection.stream(request, Twitter::Streaming::Response.new)
      expect(connection.state).to eq :connected
    end
  end

  describe '#close' do
    context 'when client is not connected' do
      subject(:connection) do
        Twitter::Streaming::Connection.new(ssl_socket_class: FakeSSLSocket)
      end

      it 'no-ops when the client is not connected' do
        expect(subject.close).to be nil
      end
    end

    context 'when connection open' do
      subject(:connection) do
        Twitter::Streaming::Connection.new(ssl_socket_class: FakeSSLSocket)
      end

      before do
        subject.stream(request, Twitter::Streaming::Response.new)
      end

      it 'closes the connection when open' do
        expect(subject.instance_variable_get('@ssl_client')).to receive(:close).once
        subject.close
      end

      it 'changes the state of the connection to closed' do
        subject.close
        expect(subject.state).to eq :closed
      end
    end
  end

  describe 'connection' do
    class DummyResponse
      def initiailze
        yield
      end

      def <<(data); end
    end

    subject(:connection) do
      Twitter::Streaming::Connection.new(tcp_socket_class: DummyTCPSocket, ssl_socket_class: DummySSLSocket)
    end

    let(:method) { :get }
    let(:uri)    { 'https://stream.twitter.com:443/1.1/statuses/sample.json' }
    let(:ssl_socket) { double('ssl_socket') }

    let(:request) { HTTP::Request.new(verb: method, uri: uri) }

    it 'requests via the proxy' do
      expect(connection.ssl_socket_class).to receive(:new).and_return(ssl_socket)
      allow(ssl_socket).to receive(:connect)

      expect(connection).to receive(:new_tcp_socket).with('stream.twitter.com', 443)
      connection.connect(request)
    end

    context 'when using a proxy' do
      let(:proxy) { {proxy_address: '127.0.0.1', proxy_port: 3328} }
      let(:request) { HTTP::Request.new(verb: method, uri: uri, proxy: proxy) }

      it 'requests via the proxy' do
        expect(connection).to receive(:new_tcp_socket).with('127.0.0.1', 3328)
        connection.connect(request)
      end

      context 'if using ssl' do
        subject(:connection) do
          Twitter::Streaming::Connection.new(tcp_socket_class: DummyTCPSocket, ssl_socket_class: DummySSLSocket, using_ssl: true)
        end

        it 'connect with ssl' do
          expect(connection.ssl_socket_class).to receive(:new).and_return(ssl_socket)
          allow(ssl_socket).to receive(:connect)

          expect(connection).to receive(:new_tcp_socket).with('127.0.0.1', 3328)
          connection.connect(request)
        end
      end
    end
  end
end
