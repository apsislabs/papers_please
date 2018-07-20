module PapersPlease
  class Policy
    attr_accessor :roles, :cache, :config_block
    attr_reader :user

    def initialize(user)
      @user          = user
      @roles         = {}
      @cache         = {}

      config_block.call
    end

    def role(name, predicate = nil, &block)
      name = name.to_sym

      raise DuplicateRole if roles[name].present?

      role = Role.new(name, predicate: predicate, definition: block)
      roles[name] << role

      role
    end

    def can?(action, subject = nil)
    end

    def scope_for(action, klass)
    end

    class << self
      def config(&block)
        @config_block = block
      end
    end
  end
end
