# -*- encoding: utf-8 -*-

class OnStomp::Connections::Serializers::Stomp_1_1
  include OnStomp::Connections::Serializers::Stomp_1
  
  # Mapping of characters to their appropriate escape sequences. This
  # is used when escaping headers for frames being written to the stream.
  CHARACTER_ESCAPES = { ':' => "\\c", "\n" => "\\n", "\\" => "\\\\" }
  
  # Mapping of escape sequences to their appropriate characters. This
  # is used when unescaping headers being read from the stream.
  ESCAPE_SEQUENCES = Hash[CHARACTER_ESCAPES.map { |k,v| [v,k] }]

  def initialize
    reset_parser
  end

  def frame_to_string frame
    frame_to_string_base(make_ct(frame)) do |k,v|
      "#{escape_header k}:#{escape_header v}\n"
    end
  end

  def escape_header s
    encode_header(s).gsub(/[:\n\\\\]/) { |c| CHARACTER_ESCAPES[c] }
  end
  
  def unescape_header s
    force_header_encoding(s).gsub(/\\.?/) do |c|
      ESCAPE_SEQUENCES[c] || raise(OnStomp::InvalidHeaderEscapeSequenceError, "#{c}")
    end
  end
  
  def split_header(str)
    col = str.index(':')
    unless col
      raise OnStomp::MalformedHeaderError, "unterminated header: '#{str}'"
    end
    [ unescape_header(str[0...col]),
      unescape_header(str[(col+1)..-1]) ]
  end
  
  # Force the body encoding to match the content-type's charset
  # if applicable.
  def prepare_parsed_frame frame
    force_body_encoding frame
  end
  
  if RUBY_VERSION >= "1.9"
    def encode_header(s)
      s.encoding.name == 'UTF-8' ? s : s.encode('UTF-8')
    end
    def force_header_encoding(s); s.tap { s.force_encoding('UTF-8') }; end
    def force_body_encoding f
      type, subtype, charset = f.content_type
      charset ||= (type == 'text') ? 'UTF-8' : 'ASCII-8BIT'
      f.body.force_encoding(charset)
      f
    end
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
    def make_ct(f); f; end
    def encode_header(s); s; end
    def force_header_encoding(s); s; end
    def force_body_encoding(f); f; end
  end
end
