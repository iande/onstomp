# -*- encoding: utf-8 -*-

# A generic encapsulation of a frame as specified by the Stomp protocol.
class OnStomp::Components::Frame
  # Regex to match content-type header value.
  # Eg: given "text/plain; ... ;charset=ISO-8859-1 ...", then
  # * $1 => type    ('text')
  # * $2 => subtype ('plain')
  # * $3 => charset ('ISO-8859-1')
  CONTENT_TYPE_REG = /^([a-z0-9!\#$&.+\-^_]+)\/([a-z0-9!\#$&.+\-^_]+)(?:.*;\s*charset=\"?([a-z0-9!\#$&.+\-^_]+)\"?)?/i
  
  attr_accessor :command, :body
  attr_reader :headers
  
  # Creates a new frame. The frame will be initialized with the optional
  # `command` name, a {OnStomp::Components::FrameHeaders headers} collection initialized
  # with the optional `headers` hash, and an optional body.
  def initialize(command=nil, headers={}, body=nil)
    @command = command
    @headers = OnStomp::Components::FrameHeaders.new(headers)
    @body = body
  end
  
  # Gets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name]`.
  #
  # @param [Object] name the header name associated with the desired value
  # @return [String] the value associated with the requested header name
  # @see OnStomp::Components::FrameHeaders#[]
  # @example
  #   frame['content-type'] #=> 'text/plain'
  def [](name); @headers[name]; end
  
  # Sets the header value paired with the supplied name.  This is a convenient
  # shortcut for `frame.headers[name] = val`.
  #
  # @param [Object] name the header name to associate with the supplied value
  # @param [Object] val the value to associate with the supplied header name
  # @return [String] the supplied value as a string, or `nil` if `nil` was supplied as the value.
  # @see OnStomp::Components::FrameHeaders#[]=
  # @example
  #   frame['content-type'] = 'text/plain' #=> 'text/plain'
  #   frame['other header'] = 42 #=> '42'
  def []=(name, val); @headers[name] = val; end
  
  # If a `content-length` header is set, returns it after converting it to
  # an integer.
  # @return [Fixnum, nil]
  def content_length
    header?(:'content-length') ? @headers[:'content-length'].to_i : nil
  end
  
  # If a `content-type` header is set, splits it into three parts: type,
  # subtype and charset. If any component of the `content-type` is missing,
  # its value will be `nil` in the returned triple. If the `content-type`
  # header is not set or does not match {OnStomp::Components::Frame::CONTENT_TYPE_REG}
  # all values in the triple will be `nil`.
  # @return [Array<String,nil>]
  def content_type
    @headers[:'content-type'] =~ CONTENT_TYPE_REG ? [$1, $2, $3] : [nil, nil, nil]
  end
  
  # Returns true if the given header name exists and its value is not an
  # empty string.
  # @param [#to_sym] name
  # @return [true,false]
  # @see OnStomp::Components::FrameHeaders#present?
  def header? name
    @headers.present? name
  end
  
  # Returns true if all given header names exist and none of their values are
  # empty strings.
  def all_headers? *names
    names.all? { |name| @headers.present?(name) }
  end
  alias :headers? :all_headers?
  
  # Returns the heart-beat configuration specified in this frame's headers.
  # If a `heart-beat` header is not set, [0, 0] will be returned. Otherwise,
  # the header value will be split on ',' and each component will be converted
  # to a non-negative integer.
  # @return [[Fixnum,Fixnum]] pair of non-negative integers that specify
  #   connection heart-beat settings
  def heart_beat
    (@headers[:'heart-beat'] || '0,0').split(',').map do |v|
      vi = v.to_i
      vi > 0 ? vi : 0
    end
  end
  
  # Sets this frame's `content-length` header to match the byte-length of
  # its body, if the body has been set.
  # @return <Fixnum,nil>
  def force_content_length
    @headers[:'content-length'] = body_length if body
  end
  
  if RUBY_VERSION >= "1.9"
    # Returns the byte-length of this frame's body
    # @return [Fixnum]
    def body_length; body.bytesize; end
  else
    # Returns the byte-length of this frame's body
    # @return [Fixnum]
    def body_length; body.length; end
  end
end
