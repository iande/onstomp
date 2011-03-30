# -*- encoding: utf-8 -*-
module RSpec
  module Mocks
    module ArgumentMatchers
      def an_onstomp_frame(command=false, header_arr=false, body=false)
        OnStompFrameMatcher.new(command, header_arr, body).tap do |m|
          m.match_command = command != false
          m.match_headers = header_arr != false
          m.match_body = body != false
        end
      end
      
      class OnStompFrameMatcher
        attr_accessor :match_command, :match_body, :match_headers
        
        def initialize(com, header_arr, body)
          @match_command = @match_body = @match_headers = true
          @expected = OnStomp::Components::Frame.new(com, {}, body)
          header_arr = [header_arr] if header_arr.is_a?(Hash)
          header_arr.each do |h|
            @expected.headers.merge!(h)
          end if header_arr.is_a?(Array)
        end
        
        def ==(actual)
          actual.is_a?(@expected.class) && matches_command(actual) &&
            matches_headers(actual) && matches_body(actual)
        end
        
        def matches_command actual
          !match_command || actual.command == @expected.command
        end
        
        def matches_body actual
          !match_body || actual.body == @expected.body
        end
        
        def matches_headers actual
          !match_headers || @expected.headers.to_hash.keys.all? { |k| @expected[k] == actual[k] }
        end
        
        def description
          frame_desc = match_command ? "#{@expected.command} frame" : "Any frame"
          header_desc = match_headers ? " with headers #{@expected.headers.to_hash.inspect}" : ''
          body_desc = match_body ? " and body '#{@expected.body}'" : ''
          [frame_desc, header_desc, body_desc].join
        end
      end
    end
  end
end
