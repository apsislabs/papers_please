module PapersPlease
  class Permission
    attr_accessor :key, :subject, :query, :predicate

    def initialize(key, subject, query: nil, predicate: nil, granted_by: nil)
      @key = key
      @subject = subject
      @query = query
      @predicate = predicate
      @granted_by = granted_by
    end

    def granted_by_other?
      @granted_by.is_a? Proc
    end

    def matches?(key, subject)
      key_matches?(key) && subject_matches?(subject)
    end

    def granted?(*args)
      return predicate.call(*args) if predicate.is_a? Proc

      false
    end

    def fetch(*args)
      return query.call(*args) if query.is_a? Proc

      nil
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
