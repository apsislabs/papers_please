# frozen_string_literal: true

module PapersPlease
  class Permission
    attr_accessor :key, :subject
    attr_reader :query, :predicate, :granted_by, :granting_class

    def initialize(key, subject, query: nil, predicate: nil, granted_by: nil, granting_class: nil)
      self.key = key
      self.subject = subject
      self.query = query
      self.predicate = predicate
      self.granted_by = granted_by
      self.granting_class = granting_class
    end

    def granted_by_other?
      @granting_class.is_a?(Class) && @granted_by.is_a?(Proc)
    end

    def matches?(key, subject)
      key_matches?(key) && subject_matches?(subject)
    end

    def granted?(*args)
      return predicate.call(*args) if predicate.is_a? Proc

      # :nocov:
      # as far as we can tell this line is unreachable, but just in case...
      false
      # :nocov:
    end

    def fetch(*args)
      return query.call(*args) if query.is_a? Proc

      nil
    end

    # Setters
    def query=(val)
      raise ArgumentError, "query must be a Proc, #{val.class} given" if val && !val.is_a?(Proc)

      @query = val
    end

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
