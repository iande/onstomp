# -*- encoding: utf-8 -*-

# A STOMP 1.1 specific connection
class OnStomp::Connections::Stomp_1_1 < OnStomp::Connections::Base
  include OnStomp::Connections::Stomp_1
  include OnStomp::Connections::Heartbeating
  # The serializer that will convert {OnStomp::Components::Frame frames} into
  # raw bytes and will convert raw bytes into {OnStomp::Components::Frame frames}
  # @return [OnStomp::Connections::Serializers::Stomp_1_1]
  attr_reader :serializer
  
  # Calls {OnStomp::Connections::Base#initialize} and creates a STOMP 1.0
  # serializer
  def initialize socket, client
    super
    @serializer = OnStomp::Connections::Serializers::Stomp_1_1.new
  end
  
  # Calls {OnStomp::Connections::Base#configure} then configures heartbeating
  # parameters.
  # @param [OnStomp::Components::Frame] connected
  # @param [{Symbol => Proc}] con_cbs
  def configure connected, con_cbs
    super
    configure_heartbeating client.heartbeats, connected.heart_beat
  end
  
  # Returns true if {OnStomp::Connections::Base#connected?} is true and
  # we have a {#pulse?}
  def connected?
    super && pulse?
  end
  
  # Creates a SUBSCRIBE frame. Sets `ack` header to 'auto' unless it is
  # already set to 'client' or 'client-individual'.
  # @return [OnStomp::Components::Frame] SUBSCRIBE frame
  def subscribe_frame d, h
    h[:ack] = 'auto' unless ['client', 'client-individual'].include?(h[:ack])
    create_frame 'SUBSCRIBE', [{:id => OnStomp.next_serial}, h, {:destination => d}]
  end
  
  # Creates an ACK frame
  # @return [OnStomp::Components::Frame] ACK frame
  def ack_frame *args
    create_ack_or_nack 'ACK', args
  end
  
  # Creates an NACK frame
  # @return [OnStomp::Components::Frame] NACK frame
  def nack_frame *args
    create_ack_or_nack 'NACK', args
  end
  
  # Creates a heartbeat frame (serialized as a single "\n" character)
  # @return [OnStomp::Components::Frame] heartbeat frame
  def heartbeat_frame
    OnStomp::Components::Frame.new
  end
  
  private
  def create_ack_or_nack(command, args)
    headers = args.last.is_a?(Hash) ? args.pop : {}
    m_id = args.shift
    sub_id = args.shift
    if m_id.is_a?(OnStomp::Components::Frame)
      sub_id = m_id[:subscription]
      m_id = m_id[:'message-id']
    end
    create_frame(command, [{:'message-id' => m_id, :subscription => sub_id }, headers]).tap do |f|
      raise ::ArgumentError, 'missing message-id or subscription headers' unless f.headers?(:'message-id', :subscription)
    end
  end
end
