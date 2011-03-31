# -*- encoding: utf-8 -*-

# Takes {OnStomp::Interfaces::FrameMethods} and makes it suitable for
# use with a {OnStomp::Failover::Client failover} client. This module is
# pretty intrinsically tied to {OnStomp::Failover::Client} 
module OnStomp::Failover::FrameMethods
  include OnStomp::Interfaces::FrameMethods
  
  OnStomp::Interfaces::FrameMethods.instance_methods(true).each do |f_meth|
    module_eval <<-EOD
      def #{f_meth}_with_an_active_client(*args, &block)
        with_an_active_client {
          #{f_meth}_without_an_active_client(*args, &block)
        }
      end
      alias :#{f_meth}_without_an_active_client :#{f_meth}
      alias :#{f_meth} :#{f_meth}_with_an_active_client
    EOD
  end
end
