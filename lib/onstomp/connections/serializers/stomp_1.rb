# -*- encoding: utf-8 -*-

# Classes that mix this in must define `split_header` and `prepare_parsed_frame`
# The method `frame_to_string_base` is provided as a factoring out of the
# common tasks of serializing a frame for STOMP 1.0 and STOMP 1.1.
module OnStomp::Connections::Serializers::Stomp_1
  # Resets the parser that converts byte strings to {OnStomp::Components::Frame frames}
  def reset_parser
    @parse_accum = ''
    @cur_frame = nil
    @parse_state = :command
  end
  
  # The common elements of serializing a {OnStomp::Components::Frame frame}
  # as a string in STOMP 1.0 and STOMP 1.1 protocols.
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
  
  # Parses a {OnStomp::Components::Frame frame} command from the buffer
  # @param [Array<String>] buffer
  def parse_command buffer
    data = buffer.shift
    eol = data.index("\n")
    if eol
      parser_flush(buffer, data, eol, :finish_command)
    else
      @parse_accum << data
    end
  end
  
  # Parses a {OnStomp::Components::Frame frame} header line from the buffer
  # @param [Array<String>] buffer
  def parse_header_line buffer
    data = buffer.shift
    eol = data.index("\n")
    if eol
      parser_flush(buffer, data, eol, :finish_header_line)
    else
      @parse_accum << data
    end
  end
  
  # Parses a {OnStomp::Components::Frame frame} body from the buffer
  # @param [Array<String>] buffer
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
  
  # Adds the substring `data[0...idx]` to the parser's accumulator,
  # unshifts the remaining data back onto the buffer, and calls `meth`
  # with the parser's accumulated string.
  # @param [Array<String>] buffer
  # @param [String] data
  # @param [Fixnum] idx
  # @param [Symbol] meth
  def parser_flush buffer, data, idx, meth
    remain = data[(idx+1)..-1]
    buffer.unshift(remain) unless remain.empty?
    __send__ meth, (@parse_accum + data[0...idx])
    @parse_accum = ''
  end
  
  # Called when a frame's command has been fully read from the buffer. This
  # method will create a new "current frame", set its
  # {OnStomp::Components::Frame#command command} attribute, and tell the parser
  # to move on to the next state.
  # @param [String] command
  def finish_command command
    @cur_frame = OnStomp::Components::Frame.new
    if command.empty?
      @parse_state = :completed
    else
      @cur_frame.command = command
      @parse_state = :header_line
    end
  end
  
  # Called when a header line has been fully read from the buffer. This
  # method will split the header line into a name/value pair,
  # {OnStomp::Components::FrameHeaders#append append} the
  # header to the "current frame" and tell the parser to move on to the next
  # state
  # @param [String] headline
  def finish_header_line headline
    if headline.empty?
      @parse_state = :body
    else
      k,v = split_header(headline)
      @cur_frame.headers.append(k, v)
    end
  end
  
  # Called when a frame's body has been fully read from the buffer. This
  # method will set the frame's {OnStomp::Components::Frame#body body}
  # attribute, call `prepare_parsed_frame` with the "current frame",
  # and tell the parser to move on to the next state.
  # @param [String] body
  def finish_body body
    @cur_frame.body = body
    prepare_parsed_frame @cur_frame
    @parse_state = :completed
  end
  
  # Takes a buffer of strings and constructs all the
  # {OnStomp::Components::Frame frames} it can from the data. The parser
  # builds a "current frame" and updates it with attributes as they are
  # parsed from the buffer. It is only safe to invoke this method from a
  # single thread as no synchronization is being performed. This will work
  # fine with the {OnStomp::Components::ThreadedProcessor threaded} processor
  # as it performs its calls all within a single thread, but if you wish
  # to develop your own processor that can call
  # {OnStomp::Connections::Base#io_process_read} across separate threads, you
  # will have to implement your own synchronization strategy.
  # @note It is NOT safe to invoke this method from multiple threads as-is.
  # @param [Array<String>] buffer
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
    # Takes the result of `frame_to_string` and forces it to use a binary
    # encoding
    # @return [String] string serialization of frame with 'ASCII-8BIT' encoding
    def frame_to_bytes frame
      frame_to_string(frame).tap { |s| s.force_encoding('ASCII-8BIT') }
    end
  else
    # Takes the result of `frame_to_string` and passes it along. Ruby 1.8.7
    # treats strings as a collection of bytes, so we don't need to do any
    # further work.
    # @return [String]
    def frame_to_bytes(frame); frame_to_string(frame); end
  end
end
