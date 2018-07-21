module PapersPlease
  class Permission < StoredBlock
    def applies?(*args)
      @block.call(*args)
    end
  end
end
