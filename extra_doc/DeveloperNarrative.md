# A Narrative for Developers

This document explores the `OnStomp` library through a narrative aimed at end
developers who wish to extend or modify the library.  It will start with the
basics and work through the important code through exposition and examples.
It may be helpful to
review the [STOMP specification](http://stomp.github.com/index.html) before
diving into this document. It's also important to note that `onstomp` can
only be used with Ruby 1.8.7+.  Support for Rubies prior to 1.8.7 does not
exist, and even requiring the library in your code will probably generate
errors.

## Clients & Frames

An instance of {OnStomp::Client} is the primary way a user will interact
with the `OnStomp` gem. It provides the helper methods to generate STOMP
frames by including the {OnStomp::Interfaces::FrameMethods} mixin, and allows
binding event callbacks by including {OnStomp::Interfaces::ClientEvents}
(which in turn includes {OnStomp::Interfaces::EventManager}.) Every client
instance will provide the same frame methods, regardless of the version of
the STOMP protocol being used. This is accomplished through by a client's use
of {OnStomp::Connections connections} and
{OnStomp::Connections::Serializers serializers} to actually generate the
frames and convert them to their appropriate string representation. You can
read more about these components in a later section.

All of the frame methods (eg: {OnStomp::Interfaces::FrameMethods#send send},
{OnStomp::Interfaces::FrameMethods#send unsubscribe}) will either generate a
new {OnStomp::Components::Frame} instance or raise an error if the STOMP
protocol version negotiated between broker and client does not support
the requested command (eg: STOMP 1.0 does not support NACK frames.)  All
frame instances are composed of a {OnStomp::Components::Frame#command command},
a set of {OnStomp::Components::Frame#headers headers}, and a
{OnStomp::Components::Frame#body body}.

A frame's {OnStomp::Components::Frame#command command} attribute is a string
that matches the corresponding STOMP command (eg: SEND, RECEIPT) with one
exception: heart-beats. The STOMP 1.1 protocol supports "heart-beating" to
let brokers and clients know that the connection is still active on the other
end by sending bare line-feed (ie: `\n`) characters between frame exchanges.
As a result, calling {OnStomp::Interfaces::FrameMethods#beat beat} on a client
will generate a frame whose command attribute is `nil`. This in turn lets the
serializer know that this isn't a true frame and it will convert it to
+"\n"+ instead of performing the normal serialization operation.

A frame's {OnStomp::Components::FrameHeaders headers} behave much like a
standard Ruby `Hash` but with a few important differences. First, the order
that header names were added is preserved. This is also true of Ruby 1.9+
hashes but not those of Ruby 1.8.7, and as a result there is some code
to maintain the ordering when running 1.8.7. Second, accessing headers
is somewhat indifferent:

    frame[:some_header] = 'a value'
    frame["some_header"] #=> 'a value'
    
What actually happens is all header names are converted to `Symbol`s
(by calling `obj.to_sym`) before any setting or getting takes place. Using
an object as a header name that does not respond to `to_sym` will raise an
error. The final major difference between headers and hashes is that header
values are only strings:

    frame[:another_header] = 42
    frame[:another_header] #=> '42'

If the object passed as a header value cannot be converted to a string an
error will be raised.

For most kinds of frames, the {OnStomp::Components::Frame#body body} attribute
will often be an empty string or `nil`. The only frames that support
non-empty bodies are SEND, MESSAGE, and ERROR.

## Events

### Frame-centric Events

Event triggering sequence for client generated frames:

1. `client.send ...` is invoked and a SEND frame is created
1. The event `before_transmitting` is triggered for the SEND frame
1. The event `before_send` is triggered for the SEND frame
1. The SEND frame is added to the {OnStomp::Connections::Base connection}'s
   write buffer
1. Some amount of time passes
1. The SEND frame is serialized and fully written to the broker.
1. The event `after_transmitting` is triggered for the SEND frame
1. The event `on_send` is triggered for the SEND frame

Event triggering sequence for broker generated frames:

1. The broker writes a MESSAGE frame to the TCP/IP socket
1. Some amount of time passes
1. The client fully reads and de-serializes the MESSAGE frame
1. The event `before_receiving` is triggered for the MESSAGE frame
1. The event `before_message` is triggered for the MESSAGE frame
1. The event `after_receiving` is triggered for the MESSAGE frame
1. The event `on_message` is triggered for the MESSAGE frame

### Connection-centric Events

Event trigger sequence for connection events:

1. An IO error occurs while the connection is reading or writing
1. The connection closes its socket
1. The connection triggers :on\_terminated
1. The connection triggers :on\_closed

## Subscription and Receipt Management

### Subscription Manager

### Receipt Manager

## URI Based Configuration

## Processors

## Connections & Serializers

### Connections

### Serializers


