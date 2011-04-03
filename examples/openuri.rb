# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'onstomp'
require 'onstomp/open-uri'

open('stomp://localhost/queue/onstomp/openuri') do |c|
  c.send "hello world!"
  c.send "a fine day to you"
  c.send "what rhymes with you?"
  c.puts "may the rats eat your eyes"
  c.send "I am now lost to your cause"
  c.puts "the inquisition is here for a reason"
end

open('stomp://localhost/queue/onstomp/openuri') do |c|
  c.each do |m|
    puts "Got a message: #{m.body}"
    break if m.body == 'what rhymes with you?'
  end
  
  c.take(2).each { |m| puts "From take(2): #{m.body}" }
  
  puts "And finally: #{c.first.body}"
end

puts "Done with open-uri examples!"

# Example output:
#
# Got a message: hello world!
# Got a message: a fine day to you
# Got a message: what rhymes with you?
# From take(2): may the rats eat your eyes
# From take(2): I am now lost to your cause
# And finally: the inquisition is here for a reason
# Done with open-uri examples!
