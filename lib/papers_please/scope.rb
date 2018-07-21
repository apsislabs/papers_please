module PapersPlease
  class Scope < StoredBlock
    def get(*args)
      @block.call(*args)
    end
  end
end
