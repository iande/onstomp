# -*- encoding: utf-8 -*-
Dir[File.expand_path('support', File.dirname(__FILE__)) + "/**/*.rb"].each { |f| require f }

if ENV['SCOV']
  begin
    require 'simplecov'
    SimpleCov.start do
      add_filter "/spec/"
    end
  rescue LoadError
  end
end

require 'onstomp'
require 'onstomp/open-uri'
require 'onstomp/failover'
