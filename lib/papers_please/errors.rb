module PapersPlease
  class AccessDenied < Error; end

  class DuplicatePermission < Error; end
  class InvalidPermission < Error; end

  class DuplicateScope < Error; end
  class InvalidScope < Error; end
end
