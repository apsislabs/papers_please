module PapersPlease
  class StoredBlock
    attr_reader :key, :subject, :block

    def initialize(key, subject, &block)
      @key = key
      @subject = subject
      @block = block
    end

    def matches?(key, subject)
      key_matches?(key) && subject_matches(subject)
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
