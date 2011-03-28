# -*- encoding: utf-8 -*-

class OnStomp::Connections::Serializers::Stomp_1_0
  include OnStomp::Connections::Serializers::Stomp_1
  
  def initialize
    reset_parser
  end

  def frame_to_string frame
    frame_to_string_base(frame) do |k,v|
      "#{k.gsub(/[\n:]/, '')}:#{v.gsub(/\n/, '')}\n"
    end
  end
  
  def split_header(str)
    col = str.index(':')
    unless col
      raise OnStomp::MalformedHeaderError, "unterminated header: '#{str}'"
    end
    [ str[0...col], str[(col+1)..-1] ]
  end
  
  # Nothing special needs to be done with Stomp 1.0 frames
  def prepare_parsed_frame frame
  end
end
