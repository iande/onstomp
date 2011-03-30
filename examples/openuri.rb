# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'open-uri'
require 'onstomp'
require 'onstomp/open-uri'

open('stomp://localhost/queue/onstomp/openuri') do |c|
  c.send "hello world!"
  c.send "a fine day to you"
  c.send "what rhymes with you?"
end

open('stomp://localhost/queue/onstomp/openuri') do |c|
  c.each do |m|
    puts "Got a message: #{m.body}"
    break if m.body == 'what rhymes with you?'
  end
end

puts "Done with open-uri examples!"