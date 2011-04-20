# -*- encoding: utf-8 -*-

# Namespace for various frame buffering strategies to keep failover working
# like it should.
module OnStomp::Failover::Buffers
end

require 'onstomp/failover/buffers/base'
require 'onstomp/failover/buffers/written'
require 'onstomp/failover/buffers/receipts'
