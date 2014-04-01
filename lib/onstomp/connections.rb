# -*- encoding: utf-8 -*-

# Namespace for protocol specific connections used to communicate with
# STOMP brokers.
module OnStomp::Connections
  # Default SSL options to use when establishing an SSL connection.
  DEFAULT_SSL_OPTIONS = {
    :verify_mode => OpenSSL::SSL::VERIFY_PEER |
      OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
    :ca_file => nil,
    :ca_path => nil,
    :cert => nil,
    :key => nil,
    :post_connection_check => true
  }
  
  # Returns a list of supported protocol versions
  # @return [Array<String>]
  def self.supported
    PROTOCOL_VERSIONS.keys.sort
  end
  
  # Filters a list of supplied versions to only those
  # that are supported. Results are in the same order as they are found
  # in {.supported}. If none of the supplied versions are supported, an
  # empty list is returned.
  # @param [Array<String>] vers versions to filter
  # @return [Array<String>]
  def self.select_supported vers
    vers = Array(vers)
    supported.select { |v| vers.include? v }
  end
  
  # Creates an initial {OnStomp::Connections::Stomp_1_0 connection} to
  # the client's broker uri, performs the CONNECT/CONNECTED frame exchange,
  # and returns a {OnStomp::Connections::Base connection} suitable for the
  # negotiated STOMP protocol version.
  # @param [OnStomp::Client] client
  # @param [{#to_sym => #to_s}] u_head user specified headers for CONNECT frame
  # @param [{#to_sym => #to_s}] c_head client specified headers for CONNECT frame
  # @param [{Symbol => Proc}] con_cbs event callbacks to install on the final
  #   connection
  # @return [OnStomp::Connections::Base] instance of Base subclass suited for
  #   negotiated protocol version
  # @raise [OnStomp::OnStompError] if negotiating the connection raises an
  #   such an error.
  def self.connect client, u_head, c_head, con_cbs, r_time, w_time
    init_con = create_connection('1.0', nil, client, r_time, w_time)
    ver, connected = init_con.connect client, u_head, c_head
    begin
      negotiate_connection(ver, init_con, client).tap do |final_con|
        final_con.configure connected, con_cbs
      end
    rescue OnStomp::OnStompError
      # Perform a blocking close.
      init_con.close true
      raise
    end
  end
  
  private
  def self.negotiate_connection vers, con, client
    supports_protocol?(vers,con) ? con :
      create_connection(vers, con.socket, client, con.read_timeout,
        con.write_timeout)
  end
  
  def self.supports_protocol? ver, con
    con.is_a? PROTOCOL_VERSIONS[ver]
  end
  
  def self.create_connection ver, sock, client, rt, wt
    unless sock
      meth = client.ssl ? :ssl :
        client.uri.respond_to?(:onstomp_socket_type) ?
          client.uri.onstomp_socket_type : :tcp
      sock = __send__(:"create_socket_#{meth}", client)
    end
    PROTOCOL_VERSIONS[ver].new(sock, client).tap do |con|
      con.read_timeout = rt
      con.write_timeout = wt
    end
  end
  
  def self.create_socket_tcp client
    TCPSocket.new(client.uri.host || 'localhost', client.uri.port)
  end
  
  def self.create_socket_ssl client
    uri = client.uri
    host = uri.host || 'localhost'
    ssl_opts = client.ssl.is_a?(Hash) ? client.ssl : {}
    ssl_opts = DEFAULT_SSL_OPTIONS.merge(ssl_opts)
    context = OpenSSL::SSL::SSLContext.new
    post_check = ssl_opts.delete(:post_connection_check)
    post_check_host = (post_check == true) ? host : post_check
    ssl_opts.each do |opt,val|
      o_meth = :"#{opt}="
      context.__send__(o_meth, val) if context.respond_to?(o_meth)
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
  # A mapping of protocol versions to the connection classes that support
  # them.
  PROTOCOL_VERSIONS = {
    '1.0' => OnStomp::Connections::Stomp_1_0,
    '1.1' => OnStomp::Connections::Stomp_1_1
  }
end
