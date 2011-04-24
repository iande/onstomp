# OnStomp

A client-side ruby gem for communicating with message brokers that support
the STOMP 1.0 and 1.1 protocols. This gem was formerly known as `stomper`,
but that name has been dropped because a
[python stomp library](http://code.google.com/p/stomper/) by the same name
already existed. Also, I think "OnStomp" better expresses the event-driven
nature of this gem.

## Installing

The OnStomp gem can be installed as a standard ruby gem:

    gem install onstomp
    
Alternatively, you can clone the
[source](https://github.com/meadvillerb/onstomp) through github.
    
## Example Usage

    # A simple message producer
    client = OnStomp.connect('stomp://user:passw0rd@broker.example.org')
    client.send('/queue/onstomp-test', 'hello world')
    client.disconnect
    
    # A simple message consumer
    client = OnStomp::Client.new('stomp+ssl://broker.example.org:10101')
    client.connect
    client.subscribe('/queue/onstomp-test', :ack => 'client') do |m|
      client.ack m
      puts "Got and ACK'd a message: #{m.body}"
    end
    
    while true
      # Keep the subscription running until the sun burns out
    end
    
## Motivation

There is a STOMP client gem named [stomp](http://gitorious.org/stomp), so why
create another gem?  OnStomp was designed around giving  users more control
over how STOMP frames are handled through an event-driven interface. All
IO reading and writing is performed through the use of non-blocking methods
in the hopes of increasing performance.

The `stomp` gem is a good gem that works well, I just desired a different
style API for working with message brokers.

## Gotchas

Both Ruby 1.8.7 and JRuby (as of 1.6.1) do not provide non-blocking read
or write methods for OpenSSL connections. While a gem named
[openssl-nonblock](https://github.com/tarcieri/openssl-nonblock) exists for
Ruby < 1.9.2, I have not personally used it and given that it's a C extension,
it may not be compatible with JRuby's openssl gem.  When an OnStomp connection
is created, the socket (SSL or TCP) is checked to see whether or not the methods
`write_nonblock` and `read_nonblock` have been defined. If not, OnStomp will
fall back on `write` for writing and `readpartial` for reading. While both of
these methods will block, the use of `IO::select` should help mitigate their
effects. I initially missed this detail, so if you're using an older version
of OnStomp (pre 1.0.4) with Ruby 1.8.7 or JRuby, you either want to upgrade
your gem or avoid `stomp+ssl://` URIs like the plague.

The final "gotcha" is more of an advanced warning.  When JRuby's support
for the Ruby 1.9 API stabilizes (and `read_nonblock` and `write_nonblock` are
available for OpenSSL connections), I will be dropping support for Ruby 1.8.x
entirely. This is probably a ways off yet, but when the time comes, I'll
post obvious warnings and increment the gem's major version. OnStomp 1.x
will always be compatible with Ruby 1.8.7+, OnStomp 2.x will be Ruby 1.9.x
only.

## Further Reading

* The [OnStomp YARD Documentation](http://mdvlrb.com/onstomp/)
* The [OnStomp Github Wiki](https://github.com/meadvillerb/onstomp/wiki)
* Some [Contrived Examples](https://github.com/meadvillerb/onstomp/tree/master/examples)
* A {file:extra_doc/UserNarrative.md User's Narrative}
* The {file:extra_doc/API.md OnStomp API Promise} (sort of)
* A {file:extra_doc/CHANGELOG.md History of Changes}

## License

OnStomp is covered by the Apache License 2.0.
See the full {file:docs/LICENSE.md LICENSE} for details.

## Thanks

There are a few people/groups I'd like to thank for helping me with the
creation of this gem.

* Lionel Cons for the good suggestions while I was implementing support for the
  STOMP 1.1 spec. Check out his Perl client [Net::STOMP::Client](http://search.cpan.org/~lcons/Net-STOMP-Client-0.9.5/lib/Net/STOMP/Client.pm)
* Brian McCallister, Johan Sørensen, Guy M. Allard and Thiago Morello for
  their work on the `stomp` gem which introduced me to the STOMP protocol.
* Hiram Chino and everyone on the stomp-spec mailing list for keeping the
  STOMP 1.1 spec moving
* Aman Gupta and contributors to
  [eventmachine](https://github.com/eventmachine/eventmachine) for the insights
  into working with non-blocking IO in Ruby
