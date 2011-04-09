# -*- encoding: utf-8 -*-

# Namespace for failover extensions.
module OnStomp::Failover
  # Raised if the supplied failover: URI is not properly formatted as
  # `failover:(uri,uri,...)?optionalParams=values`
  class InvalidFailoverURIError < OnStomp::OnStompError; end
  
  # Raised if the maximum number of retries is exceed when calling
  # {OnStomp::Failover::Client#connect}
  class MaximumRetriesExceededError < OnStomp::OnStompError; end
end

require 'onstomp/failover/uri'
require 'onstomp/failover/failover_configurable'
require 'onstomp/failover/failover_events'
require 'onstomp/failover/buffers'
require 'onstomp/failover/pools'
require 'onstomp/failover/client'
require 'onstomp/failover/new_with_failover'
