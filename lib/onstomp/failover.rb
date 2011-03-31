# -*- encoding: utf-8 -*-

module OnStomp::Failover
  class InvalidFailoverURIError < OnStomp::OnStompError; end
end

require 'onstomp/failover/uri'
require 'onstomp/failover/failover_configurable'
require 'onstomp/failover/failover_events'
require 'onstomp/failover/frame_methods'
require 'onstomp/failover/pools'
require 'onstomp/failover/client'
require 'onstomp/failover/new_with_failover'
