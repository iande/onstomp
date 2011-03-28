# -*- encoding: utf-8 -*-

# Clases that mix this in must define +split_header+ and potentially modify
# dispatch_frame
# The method +frame_to_string_base+ is provided as a factoring out of the
# common tasks of serializing a frame for Stomp 1.0 and Stomp 1.1.
module OnStomp::Connections::Serializers::Stomp_1
  def reset_parser
    @cur_command = nil
    @cur_header = nil
    @cur_body = nil
    @parse_state = :command
    @body_length = nil
    if @cur_headers
      @cur_headers.clear
    else
      @cur_headers = []
    end
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
  
  def buffer_unshift_unless_empty buffer, data, idx
    remain = data[(idx+1)..-1]
    buffer.unshift(remain) unless remain.empty?
  end
  
  def parse_command data, buffer
    eol = data.index("\n")
    if eol
      cdata = data[0...eol]
      buffer_unshift_unless_empty buffer, data, eol
    else
      cdata = data
    end
    if @cur_command
      @cur_command << cdata
    else
      @cur_command = cdata
    end
    !!eol
  end
  
  def parse_headers data, buffer
    done = false
    eol = data.index("\n")
    if eol
      cdata = data[0...eol]
      buffer_unshift_unless_empty buffer, data, eol
    else
      cdata = data
    end
    if @cur_header
      @cur_header << cdata
    else
      @cur_header = cdata
    end
    if eol
      if @cur_header.empty?
        done = true
      else
        k,v = split_header(@cur_header)
        if k == 'content-length'
          @body_length = v.to_i
        end
        @cur_headers << [k, v]
        @cur_header = nil
      end
    end
    done
  end
  
  def parse_body data, buffer
    done = false
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
      cdata = data[0...body_upto]
      buffer_unshift_unless_empty buffer, data, body_upto
      done = true
    else
      @body_length &&= (@body_length - data.length)
      cdata = data
    end
    if @cur_body
      @cur_body << cdata
    else
      @cur_body = cdata
    end
    done
  end
  
  def bytes_to_frame buffer
    until buffer.first.nil?
      data = buffer.shift
      case @parse_state
      when :command
        if parse_command data, buffer
          if @cur_command.empty?
            yield OnStomp::Components::Frame.new
            reset_parser
          else
            @parse_state = :header
          end
        end
      when :header
        if parse_headers data, buffer
          @parse_state = :body
        end
      when :body
        if parse_body data, buffer
          frame = OnStomp::Components::Frame.new
          frame.command = @cur_command
          @cur_headers.each do |(k,v)|
            frame.headers.append(k, v)
          end
          frame.body = @cur_body
          reset_parser
          prepare_parsed_frame frame
          yield frame
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
