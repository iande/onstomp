# -*- encoding: utf-8 -*-

# A specialized container for storing header name / value pairs for a
# {OnStomp::Components::Frame frame}.  This container behaves much like a `Hash`, but
# is specialized for the Stomp protocol.  Header names are always converted
# into `String`s through the use of `to_s` and may have more than one value
# associated with them.
class OnStomp::Components::FrameHeaders
  include Enumerable
  
  # Creates a new headers collection, initialized with the optional hash
  # parameter.
  # @param [Hash] headers
  # @see #merge!
  def initialize(headers={})
    @values = {}
    initialize_names
    merge! headers
  end
  
  # Merges a hash into this collection of headers. All of the keys used
  # in the hash must be convertable to Symbols through `to_sym`.
  # @note With Ruby 1.8.7, the order of hash keys may not be preserved
  # @param [Hash] hash
  def merge!(hash)
    hash.each { |k, v| self[k]= v }
  end
  
  # Reverse merges a hash into this collection of headers. The hash keys and
  # values are included only if the headers collection does not already have
  # a matching key. All of the keys used
  # in the hash must be convertable to Symbols through `to_sym`.
  # @note With Ruby 1.8.7, the order of hash keys may not be preserved
  # @param [Hash] hash
  def reverse_merge!(hash)
    hash.each { |k, v|
      self[k]= v unless set?(k)
    }
  end
  
  # Returns true if a header value has been set for the supplied header name.
  # @param [#to_sym] name the header name to test
  # @return [Boolean]
  # @example
  #   header.set? 'content-type' #=> true
  def set?(name)
    @values.key?(name.to_sym)
  end

  # Returns true if a header value has been set for the supplied header, and
  # the value is neither `nil` nor an empty string.
  # @param [#to_sym] name the header name to test
  # @return [Boolean]
  # @example
  #   header[:test1] = 'set'
  #   header[:test2] = ''
  #   header.present? :test1 #=> true
  #   header.present? :test2 #=> false
  def present?(name)
    val = self[name]
    !(val.nil? || val.empty?)
  end
  
  # Retrieves all header values associated with the supplied header name.
  # In general, this will be an array containing only the principle header
  # value; however, in the event a frame contained repeated header names,
  # this method will return all of the associated values.  The first
  # element of the array will be the principle value of the supplied
  # header name.
  #
  # @param [#to_sym] name the header name associated with the desired values (will be converted using `to_sym`)
  # @return [Array] the array of values associated with the header name.
  # @example
  #   headers.all_values('content-type') #=> [ 'text/plain' ]
  #   headers.all_values(:repeated_header) #=> [ 'principle value', '13', 'other value']
  #   headers['name'] == headers.all_values(:name).first #=> true
  def all_values(name)
    @values[name.to_sym] || []
  end
  
  # Appends a header value to the specified header name.  If the specified
  # header name is not known, the supplied value will also become the
  # principle value.  This method is used internally when constructing
  # frames sent by the broker to capture repeated header names.
  #
  # @param [#to_sym] name the header name to associate with the supplied value (will be converted using `to_s`)
  # @param [#to_s] val the header value to associate with the supplied name (will be converted using `to_s`)
  # @return [String] the supplied value as a string.
  # @example
  #   headers.append(:'new header', 'first value') #=> 'first value'
  #   headers.append('new header', nil) #=> ''
  #   headers.append('new header', 13) #=> '13'
  #   headers['new header'] #=> 'first value'
  #   headers.all('new header') #=> ['first value', '', '13']
  def append(name, val)
    name = name.to_sym
    val = val.to_s
    if @values.key?(name)
      @values[name] << val
    else
      self[name]= val
    end
    val
  end
  
  # Deletes all of the header values associated with the header name and
  # removes the header name itself.  This is analogous to the `delete`
  # method found in Hash objects.
  #
  # @param [#to_sym] name the header name to remove from this collection (will be converted using `to_sym`)
  # @return [Array] the array of values associated with the deleted header, or `nil` if the header name did not exist
  # @example
  #   headers.delete(:'content-type') #=> [ 'text/html' ]
  #   headers.delete('no such header') #=> nil
  def delete(name)
    name = name.to_sym
    if @values.key? name
      delete_name name
      @values.delete name
    end
  end
  
  # Gets the principle header value paired with the supplied header name. The name will
  # be converted to a Symbol, so must respond to the `to_sym` method.  The
  # Stomp 1.1 protocol specifies that in the event of a repeated header name,
  # the first value encountered serves as the principle value.
  #
  # @param [#to_sym] name the header name paired with the desired value (will be converted using `to_sym`)
  # @return [String] the value associated with the requested header name
  # @return [nil] if no value has been set for the associated header name
  # @example
  #   headers['content-type'] #=> 'text/plain'
  def [](name)
    name = name.to_sym
    @values[name] && @values[name].first
  end
  
  # Sets the header value paired with the supplied header name.  The name 
  # will be converted to a Symbol and must respond to `to_sym`; meanwhile,
  # the value will be converted to a String so must respond to `to_s`.
  # Setting a header value in this fashion will overwrite any repeated header values.
  #
  # @param [#to_sym] name the header name to associate with the supplied value (will be converted using `to_sym`)
  # @param [#to_s] val the value to pair with the supplied name (will be converted using `to_s`)
  # @return [String] the supplied value as a string.
  # @example
  #   headers['content-type'] = 'image/png' #=> 'image/png'
  #   headers[:'content-type'] = nil #=> ''
  #   headers['content-type'] #=> ''
  def []=(name, val)
    name = name.to_sym
    val = val.to_s
    add_name name
    @values[name] = [val]
    val
  end
  
  # Returns a new `Hash` object associating symbolized header names and their
  # principle values.
  # @return [Hash]
  def to_hash
    @values.inject({}) { |h, (k,v)| h[k] = v.first; h }
  end
  
  # Iterates over header name / value pairs, yielding them as a pair
  # of strings to the supplied block.
  # @yield [header_name, header_value]
  # @yieldparam [String] header_name
  # @yieldparam [String] header_value
  def each &block
    if block_given?
      iterate_each &block
      self
    else
      self.to_enum
    end
  end
  
  if RUBY_VERSION >= "1.9"
    def names; @values.keys; end
    
    private
    def iterate_each
      @values.each do |name, vals|
        name_str = name.to_s
        vals.each do |val|
          yield [name_str, val]
        end
      end
    end
    def initialize_names; end
    def delete_name(name); end
    def add_name(name); end
  else
    attr_reader :names

    private
    def iterate_each
      @names.each do |name|
        @values[name].each do |val|
          yield [name.to_s, val]
        end
      end
    end
    def initialize_names; @names = []; end
    def delete_name(name); @names.delete name; end
    def add_name(name); @names << name unless @values.key?(name); end
  end
end
