# -*- encoding: utf-8 -*-

# Mixin of extensions added to {OnStomp::Client clients} when they are
# created by opening a stomp:// URI.
module OnStomp::OpenURI::ClientExtensions
  attr_reader :auto_destination, :openuri_message_queue
  
  # Aliases {#send_with_openuri} as `send`
  def self.extended inst
    inst.instance_eval do
      alias :send_without_openuri :send
      alias :send :send_with_openuri
      alias :puts :send
    end
  end
  
  # Adds the ability for clients to generate SEND frames without specifying
  # a destination by using {#auto_destination} instead.
  # @return [OnStomp::Components::Frame] SEND frame
  def send_with_openuri *args, &block
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest, body = args
    if body.nil?
      body, dest = dest, verified_auto_destination
    end
    send_without_openuri dest, body, headers, &block
  end
  
  # Creates a subscription to {#auto_destination} and yields each MESSAGE frame
  # read from the subscription to the supplied block. If no block is provided
  # an enumerator is returned.
  # @yield [m] block to call for each MESSAGE frame
  # @yieldparam [OnStomp::Components::Frame] m
  # @return [Enumerator,self] 
  def each(&block)
    if block
      subscribe_to_auto_destination
      loop do
        yield openuri_message_queue.shift
      end
    else
      self.to_enum
    end
  end

  # Returns `n` frames read from the subscription. If `n` is ommited,
  # the next frame is returned, otherwise an array of the next `n` frames
  # is returned.
  # @see #each
  # @param [Fixnum,nil] n
  # @return [OnStomp::Components::Frame,Array<OnStomp::Components::Frame>]
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
  
  # Assigns the auto destination. When a stomp:// URI is opened, this
  # will initially be set to the `path` of the URI.
  # @param [String] dest
  # @return [String,nil]
  def auto_destination= dest
    @auto_destination = (dest == '/') ? nil : dest
  end
  
  private
  def subscribe_to_auto_destination
    unless @subscribe
      @openuri_message_queue = OnStomp::OpenURI::MessageQueue.new
      @subscribe = subscribe(verified_auto_destination) do |m|
        openuri_message_queue << m
      end
    end
  end
  
  def verified_auto_destination
    if auto_destination.nil? || auto_destination.empty?
      raise OnStomp::OpenURI::UnusableDestinationError
    end
    auto_destination
  end
end
