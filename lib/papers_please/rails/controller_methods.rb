# frozen_string_literal: true

module PapersPlease
  module Rails
    def self.install_controller_methods(controller)
      collisions = ControllerMethods.instance_methods(false) & controller.instance_methods
      warn_method_collisions(controller, collisions) unless collisions.empty?

      controller.include ControllerMethods unless controller < ControllerMethods
    end

    def self.warn_method_collisions(controller, collisions)
      warn "[papers_please] #{controller} already defines #{collisions.map(&:inspect).join(", ")}; " \
        "including controller helpers may change method lookup."
    end

    module ControllerMethods
      def self.included(base)
        base.helper_method :can?, :cannot? if base.respond_to? :helper_method
      end

      def policy
        @policy ||= ::PapersPlease.policy_class.new(current_user)
      end

      def can?(*args)
        policy.can?(*args)
      end

      def cannot?(*args)
        policy.cannot?(*args)
      end

      def authorize!(*args)
        policy.authorize!(*args)
      end
    end
  end
end
