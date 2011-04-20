# -*- encoding: utf-8 -*-

# Module for configurable attributes
module OnStomp::Interfaces::UriConfigurable
  # Extends `base` with {OnStomp::Interfaces::UriConfigurable::ClassMethods}
  def self.included(base)
    base.extend ClassMethods
  end

  private  
  def configure_configurable hash_opts
    config = OnStomp.keys_to_sym(CGI.parse(uri.query || '')).
      merge(OnStomp.keys_to_sym(hash_opts))
    self.class.config_attributes.each do |attr_name, attr_conf|
      attr_val = config.key?(attr_name) ? config[attr_name] :
        attr_conf.key?(:uri_attr) && uri.__send__(attr_conf[:uri_attr]) ||
        attr_conf[:default]
      __send__(:"#{attr_name}=", attr_val)
    end
  end

  # Provides attribute methods that can be configured by URI attributes
  # or query parameters.
  module ClassMethods
    # Creates a group readable and writeable attributes that can be set
    # by a URI query parameter sharing the same name, a property of a URI or
    # a default value. The value of this attribute will be transformed by
    # invoking the given block, if one has been provided.
    def attr_configurable *args, &block
      opts = args.last.is_a?(Hash) ? args.pop : {}
      args.each do |attr_name|
        init_config_attribute attr_name, opts
        attr_reader attr_name
        define_method :"#{attr_name}=" do |v|
          instance_variable_set(:"@#{attr_name}", (block ? block.call(v) : v))
        end
      end
    end
    
    # Creates a group readable and writeable attributes that can be set
    # by a URI query parameter sharing the same name, a property of a URI or
    # a default value. The value of this attribute will be transformed by
    # invoking the given block, if one has been provided. If the attributes
    # created by this method are assigned an `Array`, only the first element
    # will be used as their value.
    def attr_configurable_single *args, &block
      trans = attr_configurable_wrap lambda { |v| v.is_a?(Array) ? v.first : v }, block
      attr_configurable(*args, &trans)
    end
    
    # Creates a group readable and writeable attributes that can be set
    # by a URI query parameter sharing the same name, a property of a URI or
    # a default value. The value of this attribute will be transformed by
    # invoking the given block, if one has been provided. The attributes
    # created by this method will be treated as though they were created
    # with {#attr_configurable_single} and will also be converted into Strings.
    def attr_configurable_str *args, &block
      trans = attr_configurable_wrap lambda { |v| v.to_s }, block
      attr_configurable_single(*args, &trans)
    end
    
    # Creates a group readable and writeable attributes that can be set
    # by a URI query parameter sharing the same name, a property of a URI or
    # a default value. The value of this attribute will be transformed by
    # invoking the given block, if one has been provided. If the attributes
    # created by this method are assigned a value that is not an `Array`, the
    # value will be wrapped in an array.
    def attr_configurable_arr *args, &block
      trans = attr_configurable_wrap lambda { |v| Array(v) }, block
      attr_configurable(*args, &trans)
    end
    
    # Creates readable and writeable attributes that are automatically
    # converted into integers.
    def attr_configurable_int *args, &block
      trans = attr_configurable_wrap lambda { |v| v.to_i }, block
      attr_configurable_single(*args, &trans)
    end
    
    # Creates a group readable and writeable attributes that can be set
    # by a URI query parameter sharing the same name, a property of a URI or
    # a default value. The value of this attribute will be transformed by
    # invoking the given block, if one has been provided. The attributes
    # created by this method will be treated as though they were created
    # with {#attr_configurable_single} and will also be converted into Class
    # or Module objects.
    def attr_configurable_class *args, &block
      trans = attr_configurable_wrap lambda { |v| OnStomp.constantize(v) }, block
      attr_configurable_single(*args, &trans)
    end
    
    private
    def attr_configurable_wrap(trans, block)
      if block
        lambda { |v| block.call(trans.call(v)) }
      else
        trans
      end
    end
    
    def init_config_attribute(name, opts)
      unless respond_to?(:config_attributes)
        class << self
          def config_attributes
            @config_attributes ||= {}
          end
        end
      end
      config_attributes[name] ||= {}
      config_attributes[name].merge!(opts)
    end
  end
end
