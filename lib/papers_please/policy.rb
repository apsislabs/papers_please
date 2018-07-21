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
      cache[:permission][action] ||= {}
      return cache[:permission][action][klass] if cache[:permission][action][klass]

      applicable_roles.each do |role|
        permission = role.find_permission(action, subject)
        cache[:permission][action][subject] = permission.applies?(user, subject, action)
      end

      cache[:permission][action][subject]
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
      cache[:scope][action] ||= {}
      return cache[:scope][action][klass] if cache[:scope][action][klass]

      applicable_roles.each do |role|
        scope = role.find_scope(action, klass)
        cache[:scope][action][klass] = scope.get(user, klass, action)
      end

      cache[:scope][action][klass]
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
