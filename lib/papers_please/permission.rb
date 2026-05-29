# frozen_string_literal: true

module PapersPlease
  class Permission
    attr_reader :key, :subject, :collection, :delegation, :scope, :predicate

    alias_method :query, :scope
    alias_method :collection?, :collection

    def initialize(key, subject, scope: nil, query: nil, predicate: nil, delegation: nil, collection: false)
      raise ArgumentError, "cannot pass both :scope and :query" if scope && query

      @key = key
      @subject = subject
      @scope = validate_callable!(scope || query)
      @predicate = validate_callable!(predicate)
      @delegation = delegation
      @collection = collection
    end

    def delegated?
      delegation.is_a?(Delegation)
    end

    def granting_class
      delegation&.klass
    end

    def granted_by_other?
      delegated?
    end

    def matches?(key, subject)
      key_matches?(key) && subject_matches?(subject)
    end

    def matches_subject?(subject)
      subject_matches?(subject)
    end

    def granted?(user, subject)
      return predicate.call(user, subject) if predicate

      # :nocov:
      false
      # :nocov:
    end

    def fetch(user, klass)
      return scope.call(user, klass) if scope

      nil
    end

    def scope=(val)
      @scope = validate_callable!(val)
    end

    alias_method :query=, :scope=

    def predicate=(val)
      @predicate = validate_callable!(val)
    end

    private

    def validate_callable!(val)
      raise ArgumentError, "must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)

      val
    end

    def key_matches?(key)
      key == @key
    end

    def subject_matches?(subject)
      subject == @subject || subject.class <= @subject
    end
  end
end
