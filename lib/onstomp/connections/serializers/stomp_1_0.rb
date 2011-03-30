# -*- encoding: utf-8 -*-

# Frame serializer / parser for STOMP 1.0 connections.
class OnStomp::Connections::Serializers::Stomp_1_0
  include OnStomp::Connections::Serializers::Stomp_1
  
  # Creates a new serializer and calls {#reset_parser}
  def initialize
    reset_parser
  end

  # Converts a {OnStomp::Components::Frame frame} to a string
  # @param [OnStomp::Components::Frame] frame
  # @return [String]
  def frame_to_string frame
    frame_to_string_base(frame) do |k,v|
      "#{k.gsub(/[\n:]/, '')}:#{v.gsub(/\n/, '')}\n"
    end
  end
  
  # Splits a header line into a header name / header value pair at the first
  # ':' character and returns the pair.
  # @param [String] str header line to split
  # @return [[String, String]]
  # @raise [OnStomp::MalformedHeaderError] if the header line
  #   lacks a ':' character
  def split_header(str)
    col = str.index(':')
    unless col
      raise OnStomp::MalformedHeaderError, "unterminated header: '#{str}'"
    end
    [ str[0...col], str[(col+1)..-1] ]
  end
  
  # Nothing special needs to be done with frames parsed from a STOMP 1.0
  # connection, so this is a no-op.
  # @param [OnStomp::Components::Frame] frame
  # @return [nil]
  def prepare_parsed_frame frame
  end
end
