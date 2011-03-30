# -*- encoding: utf-8 -*-

class OnStomp::Components::URI::STOMP
  def open(*args)
    client = OnStomp::OpenURI.new(self, *args)
    if block_given?
      begin
        yield client
      ensure
        client.disconnect
      end
    end
    client
  end
end

class OnStomp::OpenURI
  ENUMERATOR_FACTORY = (RUBY_VERSION >= '1.9') ? ::Enumerator :
    ::Enumerable::Enumerator

  attr_accessor :destination

  attr_reader :client

  def initialize(uri, *args)
    @client = OnStomp::Client.new(uri, *args)
    @destination = uri.path if uri.path && !uri.path.empty? && uri.path != '/'
    @subscribed = nil
    # Install the nil processor.
    client.processor = nil
    client.connect
  end
  
  def send(*args, &block)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest, body = args
    if body.nil?
      _verify_destination_
      body, dest = dest, destination
    end
    _trans_ :send, dest, body, headers, &block
  end
  alias_method :puts, :send

  def subscribe(*args, &block)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest = args.first
    if dest
      _trans_ :subscribe, dest, headers, &block
    elsif !@subscribed
      _verify_destination_
      @subscribed = _trans_(:subscribe, destination, headers, &block)
    end
  end

  def unsubscribe(*args)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest = args.first
    if dest
      _trans_ :unsubscribe, dest, headers
    elsif @subscribed
      _trans_(:unsubscribe, @subscribed, headers).tap { |_| @subscribed = nil }
    end
  end
  
  def ack(*args, &block); _trans_ :ack, *args, &block; end
  def nack(*args, &block); _trans_ :nack, *args, &block; end
  def begin(*args, &block); _trans_ :begin, *args, &block; end
  def abort(*args, &block); _trans_ :abort, *args, &block; end
  def commit(*args, &block); _trans_ :commit, *args, &block; end
  def disconnect(*args, &block); _trans_ :disconnect, *args, &block; end
  
  def each(&block)
    if block
      # Unsubscribe first, otherwise the new block will NEVER get set up as
      # a subscription handler.
      unsubscribe
      subscribe { |m| block.call(m) }
      loop do
        client.connection.io_process
      end
    else
      ENUMERATOR_FACTORY.new(self)
    end
  end

  def first(n=nil)
    to_recv = n || 1
    received = []
    each do |m|
      received << m
      break if received.size == to_recv
    end
    n ? received : received.first
  end
  alias :take :first
  alias :gets :first
  
  private
  def _trans_ meth, *args, &block
    client.__send__(meth, *args, &block).tap do |_|
      frame_back = nil
      until frame_back
        client.connection.io_process_write do |f|
          frame_back ||= f
        end
      end
    end
  end
  
  def _verify_destination_
    raise OnStomp::OpenURI::UnusableDestinationError,
      "A valid destination could not be determined" if destination.nil? || destination.empty?
  end
end
