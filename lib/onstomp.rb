# -*- encoding: utf-8 -*-

# Copyright 2011 Ian D. Eccles
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For extensions to URI.parse for Stomp schemes.
require 'uri'
# Primarily for CGI.parse
require 'cgi'
# Sockets are fairly important in all of this.
require 'socket'
# As is openssl
require 'openssl'
# For IO#ready?
require 'io/wait'
# The socket helpers use this to delegate to the real sockets
require 'delegate'
# Threading and Mutex support
require 'thread'
# Monitor support (prevent recursive dead locking)
require 'monitor'

# Primary namespace for the `onstomp` gem
module OnStomp
  # A common base class for errors raised by the OnStomp gem
  # @abstract
  class OnStompError < StandardError; end
  
  # Low level error raised when the broker transmits data that violates
  # the Stomp protocol specification.
  # @abstract
  class FatalProtocolError < OnStompError; end
  
  # Raised when an invalid character is encountered in a header
  class InvalidHeaderCharacterError < FatalProtocolError; end
  
  # Raised when an invalid escape sequence is encountered in a header name or value
  class InvalidHeaderEscapeSequenceError < FatalProtocolError; end
  
  # Raised when a malformed header is encountered. For example, if a header
  # line does not contain ':'
  class MalformedHeaderError < FatalProtocolError; end
  
  # Raised when a malformed frame is encountered on the stream. For example,
  # if a frame is not properly terminated with the {OnStomp::FrameIO::FRAME_TERMINATOR}
  # character.
  class MalformedFrameError < FatalProtocolError; end
  
  # An error that is raised as a result of a misconfiguration of the client
  # connection
  # @abstract
  class FatalConnectionError < OnStompError; end
  
  # Raised when a connection has been configured with an unsupported protocol
  # version. This can be due to end user misconfiguration, or due to improper
  # protocol negotiation with the message broker.
  class UnsupportedProtocolVersionError < FatalConnectionError; end
  
  # Raised when an attempt to connect to the broker results in an unexpected
  # exchange.
  class ConnectFailedError < FatalConnectionError; end

  # Raised when the connection between client and broker times out.
  class ConnectionTimeoutError < FatalConnectionError; end
  
  # Raised if the command issued is not supported by the protocol version
  # negotiated between the client and broker.
  class UnsupportedCommandError < OnStompError; end
  
  # An error that is raised as a result frames being generated on
  # a transaction while it is in an invalid state.
  # @abstract
  class TransactionError < OnStompError; end

  # Raised by ThreadedReceiver to stop the receiving thread.
  class StopReceiver < StandardError; end
  
  class << self
    # Creates a new connection and immediately connects it to the broker.
    # @see #initialize
    def connect(uri, options={})
      conx = OnStomp::Client.new(uri, options)
      conx.connect
      conx
    end
    alias :open :connect
    
    # Duplicates an existing hash while transforming its keys to symbols.
    # The keys must implement the `to_sym` method, otherwise an exception will
    # be raised. This method is used internally to convert hashes keyed with
    # Strings.
    #
    # @param [{Object => Object}] hsh The hash to convert. It's keys must respond to `to_sym`.
    # @return [{Symbol => Object}]
    # @example
    #   hash = { '10' => nil, 'key2' => [3, 5, 8, 13, 21], :other => :value }
    #   OnStomp.keys_to_sym(hash) #=> { :'10' => nil, :key2 => [3, 5, 8, 13, 21], :other => :value }
    #   hash #=> { '10' => nil, 'key2' => [3, 5, 8, 13, 21], :other => :value }
    def keys_to_sym(hsh)
      hsh.inject({}) do |new_hash, (k,v)|
        new_hash[k.to_sym] = v
        new_hash
      end
    end
    
    # Generates the next serial number in a thread-safe manner. This method
    # merely initializes an instance variable to 0 if it has not been set,
    # then increments this value and returns its string representation.
    def next_serial(prefix=nil)
      Thread.exclusive do
        @next_serial_sequence ||= 0
        @next_serial_sequence += 1
        @next_serial_sequence.to_s
      end
    end

    # Converts a string to the Ruby constant it names. If the `klass` parameter
    # is a kind of `Module`, this method will return `klass` directly.
    # @param [String,Module] klass
    # @return [Module]
    # @example
    #   OnStomp.constantize('OnStomp::Frame') #=> OnStomp::Frame
    #   OnStomp.constantize('This::Constant::DoesNotExist) #=> raises NameError
    #   OnStomp.constantize(Symbol) #=> Symbol 
    def constantize(klass)
      return klass if klass.is_a?(Module) || klass.nil? || klass.respond_to?(:new)
      klass.to_s.split('::').inject(Object) do |const, named|
        next const if named.empty?
        const.const_defined?(named) ? const.const_get(named) :
          const.const_missing(named)
      end
    end
  end
end
require 'onstomp/version'
require 'onstomp/interfaces'
require 'onstomp/components'
require 'onstomp/connections'
require 'onstomp/client'
