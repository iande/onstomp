# -*- encoding: utf-8 -*-

class OnStomp::OpenURI::Client
  include OnStomp::Interfaces::FrameMethods
  attr_accessor :destination

  def initialize(uri, *args)
    @client = OnStomp::Client.new(uri, *args)
    set_default_destination uri.path
    @subscribe = nil
    @client.processor = OnStomp::OpenURI::NilProcessor
    @client.before_unsubscribe &method(:unsubscribed)
    @client.connect
  end
  
  def send_with_openuri *args, &block
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest, body = args
    if body.nil?
      body, dest = dest, verified_destination
    end
    send_without_openuri dest, body, headers, &block
  end
  alias :send_without_openuri :send
  alias :send :send_with_openuri
  alias :puts :send
  
  def subscribe_with_openuri *args, &block
    h = args.last.is_a?(Hash) ? args.pop : {}
    d = args.first
    if d
      subscribe_without_openuri d, h, &block
    elsif !@subscribe
      @subscribe = subscribe_without_openuri(verified_destination, h, &block)
    end
    subscribe_without_openuri dest, headers, &block
  end
  alias :subscribe_without_openuri :subscribe
  alias :subscribe :subscribe_with_openuri
  
  def unsubscribe_with_openuri *args
    h = args.last.is_a?(Hash) ? args.pop : {}
    unsubscribe_without_openuri(args.first || @subscribe, h)
  end
  alias :unsubscribe_without_openuri :unsubscribe
  alias :unsubscribe :unsubscribe_with_openuri
  
  def each(&block)
    if block
      # Unsubscribe first, otherwise the new block will NEVER get set up as
      # a subscription handler.
      unsubscribe
      subscribe { |m| block.call(m) }
      loop do
        # Only need to process read here, write will be processed
        # if any frames are transmitted within the block through +_trans_+
        @client.connection.io_process_read
      end
    else
      ENUMERATOR.new(self)
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
  def connection
    @client.connection
  end
  def transmit frame, cbs={}
    @client.transmit(frame,cbs).tap do |_|
      frame = nil
      @client.connection.io_process_write { |f| frame ||= f } until frame
    end
  end
  
  def verified_destination
    raise UnusableDestinationError if destination.nil? || destination.empty?
    destination
  end
  
  def set_default_destination path
    unless path.nil? || path.empty? || path == '/'
      @destination = path
    end
  end
  
  def unsubscribed u, *_
    if @subscribe && u[:id] == @subscribe[:id]
      @subscribe = nil
    end
  end
end
