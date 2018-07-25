module PapersPlease
  class Policy
    attr_accessor :roles, :config_block
    attr_reader :user

    def initialize(user)
      @user          = user
      @roles         = {}
      @cache         = {}

      config_block.call
    end

    # Add a role to the Policy
    def add_role(name, predicate = nil, &block)
      name = name.to_sym
      raise DuplicateRole if roles[name].present?

      role = Role.new(name, predicate: predicate, definition: block)
      roles[name] << role

      role
    end
    alias role add_role

    # Look up a stored permission block and call with
    # the current user and subject
    def can?(action, subject = nil)
      applicable_roles.each do |role|
        permission = role.find_permission(action, subject)
        return permission.applies?(user, subject, action)
      end
    end

    def cannot?(*args)
      !can?(*args)
    end

    def authorize!(action, subject)
      raise AccessDenied.new(action, subject) if cannot?(action, subject)
      subject
    end

    # Look up a stored scope block and call with the
    # current user and class
    def scope_for(action, klass)
      applicable_roles.each do |role|
        scope = role.find_scope(action, klass)
        return scope.get(user, klass, action)
      end
    end

    # Fetch roles that apply to the current user
    def applicable_roles
      @applicable_roles ||= roles.select do |role|
        role.applies_to?(user)
      end
    end

    class << self
      def config(&block)
        @config_block = block
      end
    end
  end
end
