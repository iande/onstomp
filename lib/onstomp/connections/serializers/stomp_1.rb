# -*- encoding: utf-8 -*-

# Clases that mix this in must define +split_header+ and potentially modify
# dispatch_frame
# The method +frame_to_string_base+ is provided as a factoring out of the
# common tasks of serializing a frame for Stomp 1.0 and Stomp 1.1.
module OnStomp::Connections::Serializers::Stomp_1
  def reset_parser
    @parse_accum = ''
    @cur_frame = nil
    @parse_state = :command
  end
  
  def frame_to_string_base frame
    if frame.command
      frame.force_content_length
      str = "#{frame.command}\n"
      frame.headers.inject(str) do |acc, (k,v)|
        acc << yield(k,v)
      end
      str << "\n"
      str << "#{frame.body}" if frame.body
      str << "\000"
      str
    else
      "\n"
    end
  end
  
  def parse_command buffer
    data = buffer.shift
    eol = data.index("\n")
    if eol
      parser_flush(buffer, data, eol, :finish_command)
    else
      @parse_accum << data
    end
  end
  
  def parse_header_line buffer
    data = buffer.shift
    eol = data.index("\n")
    if eol
      parser_flush(buffer, data, eol, :finish_header_line)
    else
      @parse_accum << data
    end
  end
  
  def parse_body buffer
    data = buffer.shift
    if rlen = @cur_frame.content_length
      rlen -= @parse_accum.length
    end
    body_upto = rlen ? (rlen < data.length && rlen) : data.index("\000")
    if body_upto
      if data[body_upto, 1] != "\000"
        raise OnStomp::MalformedFrameError, 'missing terminator'
      end
      parser_flush(buffer, data, body_upto, :finish_body)
    else
      @parse_accum << data
    end
  end
  
  def parser_flush buffer, data, idx, meth
    remain = data[(idx+1)..-1]
    buffer.unshift(remain) unless remain.empty?
    __send__ meth, (@parse_accum + data[0...idx])
    @parse_accum.clear
  end
  
  def finish_command command
    @cur_frame = OnStomp::Components::Frame.new
    if command.empty?
      @parse_state = :completed
    else
      @cur_frame.command = command
      @parse_state = :header_line
    end
  end
  def finish_header_line headline
    if headline.empty?
      @parse_state = :body
    else
      k,v = split_header(headline)
      @cur_frame.headers.append(k, v)
    end
  end
  def finish_body body
    @cur_frame.body = body
    prepare_parsed_frame @cur_frame
    @parse_state = :completed
  end
  
  def bytes_to_frame buffer
    until buffer.first.nil? && @parse_state != :completed
      if @parse_state == :completed
        yield @cur_frame
        reset_parser
      else
        __send__(:"parse_#{@parse_state}", buffer)
      end
    end
  end
  
  if RUBY_VERSION >= "1.9"
    def frame_to_bytes frame
      frame_to_string(frame).tap { |s| s.force_encoding('ASCII-8BIT') }
    end
  else
    def frame_to_bytes(frame); frame_to_string(frame); end
  end
end
