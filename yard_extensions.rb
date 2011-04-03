class ConfigurableAttributeHandler < YARD::Handlers::Ruby::AttributeHandler
  handles method_call(:attr_configurable_str)
  handles method_call(:attr_configurable_client_beats)
  handles method_call(:attr_configurable_protocols)
  handles method_call(:attr_configurable_pool)
  handles method_call(:attr_configurable_buffer)
  handles method_call(:attr_configurable_int)
  handles method_call(:attr_configurable_bool)
  namespace_only
  
  def process
    name = statement.parameters.first.jump(:symbol, :ident).source[1..-1]
    namespace.attributes[scope][name] ||= SymbolHash[:read => nil, :write => nil]
    namespace.attributes[scope][name][:read] = YARD::CodeObjects::MethodObject.new(namespace, name)
    namespace.attributes[scope][name][:write] = YARD::CodeObjects::MethodObject.new(namespace, "#{name}=")
    register namespace.attributes[scope][name][:read]
    register namespace.attributes[scope][name][:write]
  end
end

class EventMethodsHandler < YARD::Handlers::Ruby::MethodHandler
  handles method_call(:create_event_methods)
  namespace_only
  
  def process
    base_name = statement.parameters.first.jump(:symbol, :ident).source[1..-1]
    statement.parameters[1..-1].each do |pref_sexp|
      if pref_sexp
        pref = pref_sexp.jump(:symbol, :ident).source[1..-1]
        name = "#{pref}_#{base_name}"
        object = YARD::CodeObjects::MethodObject.new(namespace, name)
        register object
      end
    end
  end
end