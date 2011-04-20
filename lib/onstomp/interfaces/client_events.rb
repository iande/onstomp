# -*- encoding: utf-8 -*-

# Mixin for {OnStomp::Client client} events
# There are a few special event methods that will be passed on
# to the client's connection, they are:
# * `on_connection_established` => {OnStomp::Interfaces::ConnectionEvents#on_established}
# * `on_connection_died` => {OnStomp::Interfaces::ConnectionEvents#on_died}
# * `on_connection_terminated` => {OnStomp::Interfaces::ConnectionEvents#on_terminated}
# * `on_connection_closed` => {OnStomp::Interfaces::ConnectionEvents#on_closed}
module OnStomp::Interfaces::ClientEvents
  include OnStomp::Interfaces::EventManager

  # @group Client Frame Event Bindings
  
  # @api gem:1 STOMP:1.0,1.1
  # Can't get `before` because the CONNECT frame isn't transmitted by
  # the client.
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :connect, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when an ACK frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :ack, :before, :on
  # @api gem:1 STOMP:1.1
  # Binds a callback to be invoked when a NACK frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :nack, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a BEGIN frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :begin, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when an ABORT frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :abort, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a COMMIT frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :commit, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a SEND frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :send, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a SUBSCRIBE frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :subscribe, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when an UNSUBSCRIBE frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :unsubscribe, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a DISCONNECT frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :disconnect, :before, :on
  # @api gem:1 STOMP:1.1
  # Binds a callback to be invoked when a client heartbeat is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :client_beat, :before, :on
  
  # @group Broker Frame Event Bindings

  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when an ERROR frame is received
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :error, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a MESSAGE frame is received
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :message, :before, :on
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when a RECEIPT frame is received
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :receipt, :before, :on
  # @api gem:1 STOMP:1.1
  # Binds a callback to be invoked when a broker heartbeat is received
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :broker_beat, :before, :on

  # @group Frame Exchange Event Bindings
  
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when any frame is transmitted
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :transmitting, :before, :after
  # @api gem:1 STOMP:1.0,1.1
  # Binds a callback to be invoked when any frame is received
  # @yield [frame, client] callback invoked when event is triggered
  # @yieldparam [OnStomp::Components::Frame] frame
  # @yieldparam [OnStomp::Client] client
  create_event_methods :receiving, :before, :after
  
  # @endgroup

  # Helpers for setting up connection events through a client
  [:established, :terminated, :died, :closed, :blocked].each do |ev|
    module_eval <<-EOS
      def on_connection_#{ev}(&cb)
        if connection
          connection.on_#{ev}(&cb)
        else
          pending_connection_events[:on_#{ev}] << cb
        end
      end
    EOS
  end
  
  # Returns a hash of event bindings that should be set on a
  # {OnStomp::Connections::Base connection}, but were set on the client
  # because the connection does not exist yet.
  # @return [{Symbol => Array<Proc>}]
  def pending_connection_events
    @pending_connection_events ||= Hash.new { |h,k| h[k] = [] }
  end
  
  # Triggers an event named by the supplied frame, prefixed with the supplied
  # prefix. If the supplied frame is a 'heart-beat', origin will be used to
  # dispatch appropriate heart-beat event (client_beat or broker_beat)
  # @param [OnStomp::Components::Frame] f the frame trigger this event
  # @param [:on, :before, etc] pref the prefix for the event name
  # @param [:client, :broker] origin
  def trigger_frame_event f, pref, origin
    e = f.command ? :"#{pref}_#{f.command.downcase}" :
      :"#{pref}_#{origin}_beat"
    trigger_event e, f, self
  end
  
  # Triggers the :before_receiving event and the
  # `before` prefixed frame specific event (eg: `:before_error`).
  # @param [OnStomp::Components::Frame] f
  def trigger_before_receiving f
    trigger_event :before_receiving, f, self
    trigger_frame_event f, :before, :broker
  end
  
  # Triggers the :after_receiving event and the
  # `on` prefixed frame specific event (eg: `:on_message`)
  # @param [OnStomp::Components::Frame] f
  def trigger_after_receiving f
    trigger_event :after_receiving, f, self
    trigger_frame_event f, :on, :broker
  end
  
  # Triggers the :before_transmitting event and the
  # `before` prefixed frame specific event (eg: `:before_disconnect`).
  # @param [OnStomp::Components::Frame] f
  def trigger_before_transmitting f
    trigger_event :before_transmitting, f, self
    trigger_frame_event f, :before, :client
  end
  
  # Triggers the :after_transmitting event and the
  # `on` prefixed frame specific event (eg: `:on_send`).
  # @param [OnStomp::Components::Frame] f
  def trigger_after_transmitting f
    trigger_event :after_transmitting, f, self
    trigger_frame_event f, :on, :client
  end
end
