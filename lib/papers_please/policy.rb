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
      raise NotImplementedError, 'The #configure method of the access policy was not implemented'
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

    # Add permissions to the Role
    def add_permissions(keys)
      return unless block_given?

      Array(keys).each do |key|
        raise MissingRole unless roles.key?(key)

        yield roles[key]
      end
    end
    alias permit add_permissions

    # Look up a stored permission block and call with
    # the current user and subject
    def can?(action, subject = nil)
      applicable_roles.each do |_, role|
        permission = role.find_permission(action, subject)
        next if permission.nil?

        # Proxy permission check if granted by other
        if permission.granted_by_other?
          # Get proxied subject
          subject = subject.is_a?(Class) ? permission.granting_class : permission.granted_by.call(user, subject)

          # Get proxied permission
          permission = role.find_permission(action, subject)
        end

        # Check permission
        return permission.granted?(user, subject, action) unless permission.nil?
      end

      false
    end

    def cannot?(*args)
      !can?(*args)
    end

    def authorize!(action, subject)
      raise AccessDenied, "Access denied for #{action} on #{subject}" if cannot?(action, subject)

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
    alias query scope_for

    # Fetch roles that apply to the current user
    def applicable_roles
      @applicable_roles ||= roles.select do |_, role|
        role.applies_to?(user)
      end
    end
  end
end
