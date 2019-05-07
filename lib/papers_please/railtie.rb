require 'rails/railtie'

module PapersPlease
  class Railtie < ::Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__DIR__), 'tasks/*.rake')].each { |f| load f }
    end

    initializer :papers_plesae do
      if defined? ActionController::Base
        ActionController::Base.class_eval do
          include PapersPlease::Rails::ControllerMethods
        end
      end

      if defined? ActionController::API
        ActionController::API.class_eval do
          include PapersPlease::Rails::ControllerMethods
        end
      end
    end
  end
end
