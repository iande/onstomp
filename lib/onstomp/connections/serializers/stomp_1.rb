# -*- encoding: utf-8 -*-

# Clases that mix this in must define +split_header+ and potentially modify
# dispatch_frame
# The method +frame_to_string_base+ is provided as a factoring out of the
# common tasks of serializing a frame for Stomp 1.0 and Stomp 1.1.
module OnStomp::Connections::Serializers::Stomp_1
  def reset_parser
    @parser_accumulator = ''
    @cur_frame = nil
    @cur_command = ''
    @parse_state = :command
    @body_length = nil
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
      @parser_accumulator << data[0...eol]
      buffer_unshift_unless_empty buffer, data, eol
      yield @parser_accumulator
      @parser_accumulator = ''
    else
      @parser_accumulator << data
    end
  end
  
  def parse_header_line buffer
    data = buffer.shift
    eol = data.index("\n")
    if eol
      @parser_accumulator << data[0...eol]
      buffer_unshift_unless_empty buffer, data, eol
      yield @parser_accumulator
      @parser_accumulator = ''
    else
      @parser_accumulator << data
    end
  end
  
  def parse_body buffer
    data = buffer.shift
    body_upto = nil
    if @body_length
      if @body_length < data.length
        body_upto = @body_length
        if data[@body_length, 1] != "\000"
          raise OnStomp::MalformedFrameError, 'missing terminator'
        end
      end
    else
      body_upto = data.index("\000")
    end
    if body_upto
      buffer_unshift_unless_empty buffer, data, body_upto
      @parser_accumulator << data[0...body_upto]
      yield @parser_accumulator
      @parser_accumulator = ''
    else
      @body_length &&= (@body_length - data.length)
      @parser_accumulator << data
    end
  end
  
  def buffer_unshift_unless_empty buffer, data, idx
    remain = data[(idx+1)..-1]
    buffer.unshift(remain) unless remain.empty?
  end
  
  def parser_transition_out_command command
    @cur_frame = OnStomp::Components::Frame.new
    if command.empty?
      @parse_state = :completed
    else
      @cur_frame.command = command
      @parse_state = :header_line
    end
  end
  def parser_transition_out_header_line header_line
    if header_line.empty?
      @parse_state = :body
    else
      k,v = split_header(header_line)
      if k == 'content-length'
        @body_length = v.to_i
      end
      @cur_frame.headers.append(k, v)
    end
  end
  def parser_transition_out_body body
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
        __send__(:"parse_#{@parse_state}", buffer) do |data|
          __send__(:"parser_transition_out_#{@parse_state}", data)
        end
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
