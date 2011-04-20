# -*- encoding: utf-8 -*-

# Mixin for connection events
module OnStomp::Interfaces::ConnectionEvents
  include OnStomp::Interfaces::EventManager
  
  # @group Connection State Events

  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a connection has been fully
  # established between broker and client.
  # @yield [client, connection] callback invoked when event is triggered
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [OnStomp::Connections::Base] connection that triggered
  #   the event (in general the same as `client.connection`)
  create_event_methods :established, :on
  # @api gem:1 STOMP:1.1
  # Binds a callback to be invoked when a connection has been died due to
  # insufficient data transfer.
  # @note Only applies to STOMP 1.1 connections with heartbeating enabled.
  # @yield [client, connection] callback invoked when event is triggered
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [OnStomp::Connections::Base] connection that triggered
  #   the event (in general the same as `client.connection`)
  create_event_methods :died, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a connection has been terminated
  # (eg: closed unexpectedly due to an exception)
  # @yield [client, connection] callback invoked when event is triggered
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [OnStomp::Connections::Base] connection that triggered
  #   the event (in general the same as `client.connection`)
  create_event_methods :terminated, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a connection has been blocked
  # on writing for more than the allowed duration, closing the connection.
  # @yield [client, connection] callback invoked when event is triggered
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [OnStomp::Connections::Base] connection that triggered
  #   the event (in general the same as `client.connection`)
  create_event_methods :blocked, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a connection has been closed, either
  # through a graceful disconnect or unexpectedly.
  # @note If connection is closed unexpectedly, {#on_died} is triggered first,
  # followed by this event.
  # @yield [client, connection] callback invoked when event is triggered
  # @yieldparam [OnStomp::Client] client
  # @yieldparam [OnStomp::Connections::Base] connection that triggered
  #   the event (in general the same as `client.connection`)
  create_event_methods :closed, :on
  
  # @endgroup

  # Triggers a connection specific event.
  # @param [Symbol] event name
  def trigger_connection_event event, msg=''
    trigger_event :"on_#{event}", self.client, self, msg
  end
  
  # Takes a hash of event bindings a {OnStomp::Client client} has stored
  # and binds them to this connection, then triggers `on_established`.
  # This allows users to add callbacks for
  # connection events before the connection exist and have said callbacks
  # installed once the connection is created.
  # @param [{Symbol => Array<Proc>}] callbacks to install, keyed by event name
  # @see OnStomp::Interfaces::ClientEvents#pending_connection_events
  def install_bindings_from_client ev_hash
    ev_hash.each do |ev, cbs|
      cbs.each { |cb| bind_event(ev, cb) }
    end
    trigger_connection_event :established, "STOMP #{self.version} connection negotiated"
  end
end
