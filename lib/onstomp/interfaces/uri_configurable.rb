# -*- encoding: utf-8 -*-

# Module for configurable attributes
module OnStomp::Interfaces::UriConfigurable
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
  
  module ClassMethods
    def attr_configurable *args, &block
      opts = args.last.is_a?(Hash) ? args.pop : {}
      args.each do |attr_name|
        __init_config_attribute__ attr_name, opts
        define_method attr_name do
          instance_variable_get(:"@#{attr_name}")
        end
        define_method :"#{attr_name}=" do |v|
          instance_variable_set(:"@#{attr_name}", (block ? block.call(v) : v))
        end
      end
    end
    
    def attr_configurable_single *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| v.is_a?(Array) ? v.first : v }, block
      attr_configurable(*args, &trans)
    end
    
    def attr_configurable_str *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| v.to_s }, block
      attr_configurable_single(*args, &trans)
    end
    
    def attr_configurable_arr *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| Array(v) }, block
      attr_configurable(*args, &trans)
    end
    
    def attr_configurable_class *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| OnStomp.constantize(v) }, block
      attr_configurable_single(*args, &trans)
    end
    
    def attr_configurable_int *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| v.to_i }, block
      attr_configurable_single(*args, &trans)
    end
    
    def attr_configurable_float *args, &block
      trans = __attr_configurable_wrap__ lambda { |v| v.to_f }, block
      attr_configurable_single(*args, &trans)
    end
    
    private
    def __attr_configurable_wrap__(trans, block)
      if block
        lambda { |v| block.call(trans.call(v)) }
      else
        trans
      end
    end
    
    def __init_config_attribute__(name, opts)
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
