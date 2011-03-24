# -*- encoding: utf-8 -*-

# Clases that mix this in must define +split_header+ and potentially modify
# dispatch_frame
# The method +frame_to_string_base+ is provided as a factoring out of the
# common tasks of serializing a frame for Stomp 1.0 and Stomp 1.1.
module OnStomp::Connections::Serializers::Stomp_1
  def init_serializer
    reset_parser
  end
  
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
  
  def bytes_to_frame buffer
    until buffer.first.nil?
      data = buffer.shift
      case @parse_state
      when :command
        eol = data.index("\n")
        if eol
          com_data = data[0...eol]
          remain = data[(eol+1)..-1]
          buffer.unshift(remain) unless remain.empty?
          @body_length = nil
          @cur_header = nil
          @parse_state = :header
        else
          com_data = data
        end
        if @cur_command
          @cur_command << com_data
        else
          @cur_command = com_data
        end
        if eol && (@cur_command.nil? || @cur_command.empty?)
          yield OnStomp::Components::Frame.new
          reset_parser
        end
      when :header
        eol = data.index("\n")
        if eol
          head_data = data[0...eol]
          remain = data[(eol+1)..-1]
          buffer.unshift(remain) unless remain.empty?
        else
          head_data = data
        end
        if @cur_header
          @cur_header << head_data
        else
          @cur_header = head_data
        end
        if eol
          if @cur_header.empty?
            @cur_body = nil
            @parse_state = :body
          else
            k,v = split_header(@cur_header)
            if k == 'content-length'
              @body_length = v.to_i
            end
            @cur_headers << [k, v]
            @cur_header = nil
          end
        end
      when :body
        frame_completed = false
        if @body_length
          if @body_length < data.length
            if data[@body_length, 1] != "\000"
              raise OnStomp::MalformedFrameError, "missing terminator"
            end
            body_data = data[0...@body_length]
            remain = data[(@body_length+1)..-1]
            buffer.unshift(remain) unless remain.empty?
            @body_length = nil
            frame_completed = true
          else
            @body_length -= data.length
            body_data = data
          end
        else
          term = data.index("\000")
          if term
            body_data = data[0...term]
            remain = data[(term+1)..-1]
            buffer.unshift(remain) unless remain.empty?
            frame_completed = true
          else
            body_data = data
          end
        end
        if @cur_body
          @cur_body << body_data
        else
          @cur_body = body_data
        end
        if frame_completed
          frame = OnStomp::Components::Frame.new
          unless @cur_command.empty?
            frame.command = @cur_command
            @cur_headers.each do |(k,v)|
              frame.headers.append(k, v)
            end
            frame.body = @cur_body
          end
          reset_parser
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
    def frame_to_bytes frame
      frame_to_string frame
    end
  end
end
