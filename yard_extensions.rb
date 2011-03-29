class ConfigurableAttributeHandler < YARD::Handlers::Ruby::AttributeHandler
  handles method_call(:attr_configurable_str)
  handles method_call(:attr_configurable_client_beats)
  handles method_call(:attr_configurable_protocols)
  namespace_only
  
  def process
    name = statement.parameters.first.jump(:symbol, :ident).source
    namespace.attributes[scope][name] ||= SymbolHash[:read => nil, :write => nil]
    namespace.attributes[scope][name][:read] = YARD::CodeObjects::MethodObject.new(namespace, name)
    namespace.attributes[scope][name][:write] = YARD::CodeObjects::MethodObject.new(namespace, "#{name}=")
    register namespace.attributes[scope][name][:read]
    register namespace.attributes[scope][name][:write]
  end
end
