module PapersPlease
  class Policy
    attr_accessor :roles
    attr_reader :user

    def initialize(user)
      @user          = user
      @roles         = {}
      @cache         = {}

      configure
    end

    def configure
      raise NotImplementedError
    end

    # Add a role to the Policy
    def add_role(name, predicate = nil, &block)
      name = name.to_sym
      raise DuplicateRole if roles.key?(name)

      role = Role.new(name, predicate: predicate, definition: block)
      roles[name] = role

      role
    end
    alias role add_role

    # Look up a stored permission block and call with
    # the current user and subject
    def can?(action, subject = nil)
      applicable_roles.each do |_, role|
        permission = role.find_permission(action, subject)
        return permission.granted?(user, subject, action) unless permission.nil?
      end

      false
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
      applicable_roles.each do |_, role|
        permission = role.find_permission(action, klass)
        return permission.fetch(user, klass, action) unless permission.nil?
      end

      nil
    end

    # Fetch roles that apply to the current user
    def applicable_roles
      @applicable_roles ||= roles.select do |_, role|
        role.applies_to?(user)
      end
    end
  end
end
