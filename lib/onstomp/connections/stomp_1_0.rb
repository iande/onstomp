# -*- encoding: utf-8 -*-

# A STOMP 1.0 specific connection
class OnStomp::Connections::Stomp_1_0 < OnStomp::Connections::Base
  include OnStomp::Connections::Stomp_1
  # The serializer that will convert {OnStomp::Components::Frame frames} into
  # raw bytes and will convert raw bytes into {OnStomp::Components::Frame frames}
  # @return [OnStomp::Connections::Serializers::Stomp_1_0]
  attr_reader :serializer

  # Calls {OnStomp::Connections::Base#initialize} and creates a STOMP 1.0
  # serializer
  def initialize socket, client
    super
    @serializer = OnStomp::Connections::Serializers::Stomp_1_0.new
  end
  
  # Creates a SUBSCRIBE frame. Sets `ack` header to 'auto' unless it is
  # already set to 'client'.
  # @return [OnStomp::Components::Frame] SUBSCRIBE frame
  def subscribe_frame d, h
    h[:ack] = 'auto' unless h[:ack] == 'client'
    create_frame 'SUBSCRIBE', [{:id => OnStomp.next_serial}, h, {:destination => d}]
  end

  # Creates an ACK frame
  # @return [OnStomp::Components::Frame] ACK frame
  def ack_frame *args
    headers = args.last.is_a?(Hash) ? args.pop : {}
    m_id = args.shift
    m_id = m_id[:'message-id'] if m_id.is_a?(OnStomp::Components::Frame)
    create_frame('ACK', [{:'message-id' => m_id}, headers]).tap do |f|
      raise ArgumentError, 'no message-id to ACK' unless f.header?(:'message-id')
    end
  end
end
