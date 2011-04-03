# -*- encoding: utf-8 -*-
require 'open-uri'

class OnStomp::Components::URI::STOMP
  # Creates a new {OnStomp::Client}, extends it with
  # {OnStomp::OpenURI::ClientExtensions} and either returns it directly or
  # connects it, yields it to a given block and the disconnects it.
  # @param [arg1, arg2, ...] args additional arguments to pass to {OnStomp::Client#initialize}
  # @yield [client] block to evaluate within a connected client
  # @yieldparam [OnStomp::Client] client
  # @return [OnStomp::Client]
  def open(*args)
    client = OnStomp::Client.new(self, *args)
    client.extend OnStomp::OpenURI::ClientExtensions
    client.auto_destination = self.path
    if block_given?
      begin
        client.connect
        yield client
      ensure
        client.disconnect
      end
    end
    client
  end
end

# Namespace for OnStomp open-uri extensions.
module OnStomp::OpenURI
  # Raised if a client's
  # {OnStomp::OpenURI::ClientExtensions#auto_destination auto_destination} has
  # not been properly set.
  class UnusableDestinationError < OnStomp::OnStompError; end
end

require 'onstomp/open-uri/message_queue'
require 'onstomp/open-uri/client_extensions'
