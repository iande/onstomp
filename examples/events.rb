# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'onstomp'

puts "Starting demo"
puts "----------------------------"

client = OnStomp::Client.new("stomp://localhost")

client.before_transmitting do |frame, _|
  puts "Frame headers [#{frame.command}] before modification: #{frame.headers.to_a.inspect}"
  frame[:'x-alt-header'] = 'another value'
end

client.before_send do |frame, _|
  puts "SEND headers before modification: #{frame.headers.to_a.inspect}"
  frame[:'x-misc-header'] = 'this is a test'
end

client.after_transmitting do |frame, _|
  puts "Final frame headers [#{frame.command}]: #{frame.headers.to_a.inspect}"
end

client.before_disconnect do |frame, _|
  puts "Disconnecting from broker"
end

client.on_connection_established do |client, con|
  puts "=== Connected to broker using protocol #{con.version} ==="
end

client.on_connection_closed do |client, con|
  puts "=== Connection has been closed ==="
end

client.on_connection_terminated do |client, con|
  puts "=== Connection closed unexpectedly ==="
end

receipt_count = 0
client.connect
client.send("/queue/onstomp/test", "hello world") do |r|
  puts "---- Got receipt #{r[:'receipt-id']} ----"
  raise ArgumentError, 'blam!'
  receipt_count += 1
end

while receipt_count < 1 && client.connected?
end

client.disconnect rescue nil

puts "----------------------------"
puts "End of demo"

# Example output:
#
#
# Starting demo
# ----------------------------
# Final frame headers [CONNECT]: [["accept-version", "1.0,1.1"], ["host", "localhost"], ["heart-beat", "0,0"], ["login", ""], ["passcode", ""]]
# === Connected to broker using protocol 1.0 ===
# Frame headers [SEND] before modification: [["destination", "/queue/onstomp/test"], ["receipt", "1"]]
# SEND headers before modification: [["destination", "/queue/onstomp/test"], ["receipt", "1"], ["x-alt-header", "another value"]]
# Final frame headers [SEND]: [["destination", "/queue/onstomp/test"], ["receipt", "1"], ["x-alt-header", "another value"], ["x-misc-header", "this is a test"], ["content-length", "11"]]
# ---- Got receipt 1 ----
# === Connection closed unexpectedly ===
# Frame headers [DISCONNECT] before modification: []
# Disconnecting from broker
# === Connection has been closed ===
# ----------------------------
# End of demo
