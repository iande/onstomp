# -*- encoding: utf-8 -*-

# Mixin for connections to include heartbeating functionality.
module OnStomp::Connections::Heartbeating
  # A pair of integers indicating the maximum number of milliseconds the
  # client and broker can go without transmitting data respectively. If
  # either value is 0, the respective heartbeating is not enabled.
  # @return [[Fixnum, Fixnum]]
  attr_reader :heartbeating
  
  # Configures heartbeating strategy by taking the maximum timeout
  # for clients and brokers.  If either pair contains a zero, the respective
  # beating is disabled.
  # @param [[Fixnum, Fixnum]] client_beats
  # @param [[Fixnum, Fixnum]] broker_beats
  def configure_heartbeating client_beats, broker_beats
    c_x, c_y = client_beats
    s_x, s_y = broker_beats
    @heartbeating = [ (c_x == 0||s_y == 0 ? 0 : [c_x,s_y].max), 
      (c_y == 0||s_x == 0 ? 0 : [c_y,s_x].max) ]
  end
  
  # Returns true if both the client and broker are transmitting data in
  # accordance with the heartbeating strategy. If this method returns false,
  # the connection is effectively dead and should be {OnStomp::Connections::Base#close closed}
  # @return [true, false]
  def pulse?
    client_pulse? && broker_pulse?
  end
  
  # Maximum number of milliseconds allowed between bytes being sent by
  # the client, or 0 if there is no limit. This method will add a 10% margin
  # of error to the timeout determined from heartbeat negotiation to allow a
  # little slack before a connection is deemed dead.
  # @return [Fixnum]
  def heartbeat_client_limit
    unless defined?(@heartbeat_client_limit)
      @heartbeat_client_limit = heartbeating[0] > 0 ? (1.1 * heartbeating[0]) : 0
    end
    @heartbeat_client_limit
  end
  
  # Maximum number of milliseconds allowed between bytes being sent from
  # the broker, or 0 if there is no limit. This method will add a 10% margin
  # of error to the timeout determined from heartbeat negotiation to allow a
  # little slack before a connection is deemed dead.
  # @return [Fixnum]
  def heartbeat_broker_limit
    unless defined?(@heartbeat_broker_limit)
      @heartbeat_broker_limit = heartbeating[1] > 0 ? (1.1 * heartbeating[1]) : 0
    end
    @heartbeat_broker_limit
  end

  # Returns true if client-side heartbeating is disabled, or 
  # {OnStomp::Connections::Base#duration_since_transmitted} has not exceeded {#heartbeat_client_limit}
  # @return [true, false]
  def client_pulse?
    heartbeat_client_limit == 0 || duration_since_transmitted <= heartbeat_client_limit
  end

  # Returns true if broker-side heartbeating is disabled, or 
  # {OnStomp::Connections::Base#duration_since_received} has not exceeded {#heartbeat_broker_limit}
  # @return [true, false]
  def broker_pulse?
    heartbeat_broker_limit == 0 || duration_since_received <= heartbeat_broker_limit
  end
end
