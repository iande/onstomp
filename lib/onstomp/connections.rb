# -*- encoding: utf-8 -*-

module OnStomp::Connections
  DEFAULT_SSL_OPTIONS = {
    :verify_mode => OpenSSL::SSL::VERIFY_PEER |
      OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
    :ca_file => nil,
    :ca_path => nil,
    :cert => nil,
    :key => nil,
    :post_connection_check => true
  }
  
  def self.supported
    PROTOCOL_VERSIONS.keys.sort
  end
  
  def self.select_supported vers
    vers = Array(vers)
    supported.select { |v| vers.include? v }
  end
  
  def self.create_for client
    meth = client.ssl ? :ssl :
      client.uri.respond_to?(:onstomp_socket_type) ?
        client.uri.onstomp_socket_type : :tcp
    create_connection '1.0', __send__(:"create_socket_#{meth}", client), client
  end
  
  def self.negotiate_connection vers, con, frame, client
    if supports_protocol? vers, con
      con
    else
      create_connection vers, con.socket, client
    end.tap { |ncon| ncon.configure frame, client }
  end
  
  private
  def self.supports_protocol? ver, con
    con.is_a? PROTOCOL_VERSIONS[ver]
  end
  
  def self.create_connection ver, sock, disp
    PROTOCOL_VERSIONS[ver].new sock, disp
  end
  
  def self.create_socket_tcp client
    TCPSocket.new(client.uri.host || 'localhost', client.uri.port)
  end
  
  def self.create_socket_ssl client
    uri = client.uri
    host = uri.host || 'localhost'
    ssl_opts = {} unless ssl_opts.is_a?(Hash)
    ssl_opts = DEFAULT_SSL_OPTIONS.merge(ssl_opts)
    context = OpenSSL::SSL::SSLContext.new
    post_check = ssl_opts.delete(:post_connection_check)
    post_check_host = (post_check == true) ? host : post_check
    DEFAULT_SSL_OPTIONS.keys.each do |k|
      context.__send__(:"#{k}=", ssl_opts[k]) if ssl_opts.key?(k)
    end
    tcp_sock = create_socket_tcp(client)
    socket = OpenSSL::SSL::SSLSocket.new(tcp_sock, context)
    socket.sync_close = true
    socket.connect
    socket.post_connection_check(post_check_host) if post_check_host
    socket
  end
end

require 'onstomp/connections/serializers'
require 'onstomp/connections/base'
require 'onstomp/connections/stomp_1'
require 'onstomp/connections/heartbeating'
require 'onstomp/connections/stomp_1_0'
require 'onstomp/connections/stomp_1_1'

module OnStomp::Connections
  PROTOCOL_VERSIONS = {
    '1.0' => OnStomp::Connections::Stomp_1_0,
    '1.1' => OnStomp::Connections::Stomp_1_1
  }
end
