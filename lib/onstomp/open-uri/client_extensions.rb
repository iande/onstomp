# -*- encoding: utf-8 -*-

module OnStomp::OpenURI::ClientExtensions
  attr_reader :auto_destination, :openuri_message_queue
  
  def self.extended inst
    inst.instance_eval do
      alias :send_without_openuri :send
      alias :send :send_with_openuri
      alias :puts :send
    end
  end
  
  def send_with_openuri *args, &block
    headers = args.last.is_a?(Hash) ? args.pop : {}
    dest, body = args
    if body.nil?
      body, dest = dest, verified_auto_destination
    end
    send_without_openuri dest, body, headers, &block
  end
  
  def each(&block)
    if block
      subscribe_to_auto_destination
      loop do
        yield openuri_message_queue.shift
      end
    else
      OnStomp::ENUMERATOR_KLASS.new(self)
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
