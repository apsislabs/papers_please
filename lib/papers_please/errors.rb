module PapersPlease
  class Error < StandardError; end

  class AccessDenied < Error; end

  class DuplicateRole < Error; end
  class MissingRole < Error; end

  class DuplicatePermission < Error; end
  class InvalidPermission < Error; end

  class DuplicateScope < Error; end
  class InvalidScope < Error; end
end
