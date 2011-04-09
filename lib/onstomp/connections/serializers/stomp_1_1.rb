# -*- encoding: utf-8 -*-

# Frame serializer / parser for STOMP 1.1 connections.
class OnStomp::Connections::Serializers::Stomp_1_1
  include OnStomp::Connections::Serializers::Stomp_1
  
  # Mapping of characters to their appropriate escape sequences. This
  # is used when escaping headers for frames being written to the stream.
  CHARACTER_ESCAPES = { ':' => "\\c", "\n" => "\\n", "\\" => "\\\\" }
  
  # Mapping of escape sequences to their appropriate characters. This
  # is used when unescaping headers being read from the stream.
  ESCAPE_SEQUENCES = Hash[CHARACTER_ESCAPES.map { |k,v| [v,k] }]

  # Creates a new serializer and calls {#reset_parser}
  def initialize
    reset_parser
  end

  # Converts a {OnStomp::Components::Frame frame} to a string
  # @param [OnStomp::Components::Frame] frame
  # @return [String]
  def frame_to_string frame
    frame_to_string_base(make_ct(frame)) do |k,v|
      "#{escape_header k}:#{escape_header v}\n"
    end
  end

  # Escapes a header name or value by replacing special characters with
  # their appropriate escape sequences. The header will also be encoded to
  # 'UTF-8' when using Ruby 1.9+
  # @param [String] s header name or value
  # @return [String]
  def escape_header s
    encode_header(s).gsub(/[:\n\\\\]/) { |c| CHARACTER_ESCAPES[c] }
  end
  
  # Unescapes a header name or pair parsed from the read buffer by converting
  # known escape sequences into their special characters. The header string
  # will have a 'UTF-8' encoding forced upon it when using Ruby 1.9+, as per
  # the STOMP 1.1 spec.
  # @param [String] s header name or value
  # @return [String]
  # @raise [OnStomp::InvalidHeaderEscapeSequenceError]
  #   if an unknown escape sequence is present in the header name or value
  def unescape_header s
    force_header_encoding(s).gsub(/\\.?/) do |c|
      ESCAPE_SEQUENCES[c] || raise(OnStomp::InvalidHeaderEscapeSequenceError, "#{c}")
    end
  end
  
  # Splits a header line into a header name / header value pair at the first
  # ':' character {#unescape_header unescapes} them, and returns the pair.
  # @param [String] str header line to split
  # @return [[String, String]]
  # @raise [OnStomp::MalformedHeaderError] if the header line
  #   lacks a ':' character
  def split_header(str)
    col = str.index(':')
    unless col
      raise OnStomp::MalformedHeaderError, "unterminated header: '#{str}'"
    end
    [ unescape_header(str[0...col]),
      unescape_header(str[(col+1)..-1]) ]
  end
  
  # Forces the frame's body to match the charset specified in its `content-type`
  # header, if applicable.
  # @param [OnStomp::Components::Frame] frame
  def prepare_parsed_frame frame
    force_body_encoding frame
  end
  
  if RUBY_VERSION >= "1.9"
    # Encodes the given string to 'UTF-8'
    # @note No-op for Ruby 1.8.x
    # @param [String] s
    # @return [String]
    def encode_header(s)
      s.encoding.name == 'UTF-8' ? s : s.encode('UTF-8')
    end
    # Forces the encoding of the given string to 'UTF-8'
    # @note No-op for Ruby 1.8.x
    # @param [String] s
    # @return [String]
    def force_header_encoding(s); s.tap { s.force_encoding('UTF-8') }; end
    # Forces the encoding of the given frame's body to match its charset.
    # @note No-op for Ruby 1.8.x
    # @param [OnStomp::Components::Frame] f
    # @return [OnStomp::Components::Frame]
    def force_body_encoding f
      type, subtype, charset = f.content_type
      charset ||= (type == 'text') ? 'UTF-8' : 'ASCII-8BIT'
      f.body.force_encoding(charset)
      f
    end
    # Set an appropriate `content-type` header with `charset` parameter for
    # frames with a text body
    # @note No-op for Ruby 1.8.x
    # @param [OnStomp::Components::Frame] f
    # @return [OnStomp::Components::Frame]
    def make_ct f
      return f if f.body.nil?
      t, st = f.content_type
      enc = f.body.encoding.name
      if enc != 'ASCII-8BIT'
        f[:'content-type'] = "#{t||'text'}/#{st||'plain'};charset=#{enc}"
      end
      f
    end
  else
    # Encodes the given string to 'UTF-8'
    # @note No-op for Ruby 1.8.x
    # @param [String] s
    # @return [String]
    def encode_header(s); s; end
    # Forces the encoding of the given string to 'UTF-8'
    # @note No-op for Ruby 1.8.x
    # @param [String] s
    # @return [String]
    def force_header_encoding(s); s; end
    # Forces the encoding of the given frame's body to match its charset.
    # @note No-op for Ruby 1.8.x
    # @param [OnStomp::Components::Frame] f
    # @return [OnStomp::Components::Frame]
    def force_body_encoding(f); f; end
    # Set an appropriate +content-type+ header with `charset` parameter for
    # frames with a text body
    # @note No-op for Ruby 1.8.x
    # @param [OnStomp::Components::Frame] f
    # @return [OnStomp::Components::Frame]
    def make_ct(f); f; end
  end
end
