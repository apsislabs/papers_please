# frozen_string_literal: true

module PapersPlease
  class Permission
    attr_accessor :key, :subject, :collection
    attr_reader :scope, :predicate, :granted_by, :granting_class

    alias_method :query, :scope
    alias_method :collection?, :collection

    def initialize(key, subject, scope: nil, query: nil, predicate: nil, granted_by: nil, granting_class: nil, collection: false)
      raise ArgumentError, "cannot pass both :scope and :query" if scope && query

      self.key = key
      self.subject = subject
      self.scope = scope || query
      self.predicate = predicate
      self.granted_by = granted_by
      self.granting_class = granting_class
      self.collection = collection
    end

    def granted_by_other?
      @granting_class.is_a?(Class) && @granted_by.is_a?(Proc)
    end

    def matches?(key, subject)
      key_matches?(key) && subject_matches?(subject)
    end

    def granted?(*args)
      return predicate.call(*args) if predicate.is_a?(Proc)

      # :nocov:
      false
      # :nocov:
    end

    def fetch(*args)
      return scope.call(*args) if scope.is_a?(Proc)

      nil
    end

    def scope=(val)
      raise ArgumentError, "scope must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)

      @scope = val
    end

    alias_method :query=, :scope=

    def predicate=(val)
      raise ArgumentError, "predicate must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)

      @predicate = val
    end

    def granted_by=(val)
      raise ArgumentError, "granted_by must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)

      @granted_by = val
    end

    def granting_class=(val)
      raise ArgumentError, "granting_class must be a Class, #{val.class} given" if val && !val.is_a?(Class)

      @granting_class = val
    end

    private

    def key_matches?(key)
      key == @key
    end

    def subject_matches?(subject)
      subject == @subject || subject.class <= @subject
    end
  end
end
