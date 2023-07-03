# frozen_string_literal: true

module PapersPlease
  module Rails
    module ControllerMethods
      def self.included(base)
        base.helper_method :can?, :cannot?, :policy if base.respond_to? :helper_method
      end

      def policy
        @policy ||= ::PapersPlease::Policy.new(current_user)
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
