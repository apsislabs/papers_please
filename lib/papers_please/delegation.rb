# frozen_string_literal: true

module PapersPlease
  Delegation = Struct.new(:klass, :resolver) do
    def resolve(user, subject)
      resolver.call(user, subject)
    end
  end
end
