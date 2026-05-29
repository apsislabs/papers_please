# frozen_string_literal: true

module PapersPlease
  class Permission
    attr_accessor :key, :subject, :collection, :delegation
    attr_reader :scope, :predicate

    alias_method :query, :scope
    alias_method :collection?, :collection

    def initialize(key, subject, scope: nil, query: nil, predicate: nil, delegation: nil, collection: false)
      raise ArgumentError, "cannot pass both :scope and :query" if scope && query

      self.key = key
      self.subject = subject
      self.scope = scope || query
      self.predicate = predicate
      self.delegation = delegation
      self.collection = collection
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

    def granted?(*args)
      return Callable.call(predicate, *args) if predicate

      # :nocov:
      false
      # :nocov:
    end

    def fetch(*args)
      return Callable.call(scope, *args) if scope

      nil
    end

    def scope=(val)
      validate_callable!(:scope, val)
      @scope = val
    end

    alias_method :query=, :scope=

    def predicate=(val)
      validate_callable!(:predicate, val)
      @predicate = val
    end

    private

    def validate_callable!(name, val)
      raise ArgumentError, "#{name} must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)
    end

    def key_matches?(key)
      key == @key
    end

    def subject_matches?(subject)
      subject == @subject || subject.class <= @subject
    end
  end
end
