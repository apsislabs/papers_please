# frozen_string_literal: true

require "rails/railtie"

module PapersPlease
  class Railtie < ::Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), "tasks", "*.rake")].each { |f| load f }
    end

    initializer :papers_please do
      PapersPlease::Rails.install_controller_methods(ActionController::Base) if defined? ActionController::Base
      PapersPlease::Rails.install_controller_methods(ActionController::API) if defined? ActionController::API
    end
  end
end
