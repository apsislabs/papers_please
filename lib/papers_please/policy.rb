# frozen_string_literal: true

module PapersPlease
  class Policy
    attr_accessor :roles

    attr_reader :fallthrough, :user

    def initialize(user)
      @user          = user
      @default_scope = nil
      @roles         = {}
      @cache         = {}

      configure
    end

    def allow_fallthrough
      @fallthrough = true
    end

    def default_scope(scope)
      @default_scope = scope
    end

    def configure
      raise NotImplementedError, 'The #configure method of the access policy was not implemented'
    end

    # Add a role to the Policy
    def add_role(name, predicate = nil)
      name = name.to_sym
      raise DuplicateRole if roles.key?(name)

      role = Role.new(name, predicate: predicate)
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
    def can?(action, subject = nil, roles: nil)
      roles_to_check(roles: roles).each do |_, role|
        permission = role&.find_permission(action, subject)
        next if permission.nil?

        # Proxy permission check if granted by other
        subject, permission = get_proxied_permission(permission, action, subject, role) if permission.granted_by_other?

        # Check permission
        granted = permission_granted?(permission, action, subject)
        next if granted.nil? || (granted == false && fallthrough)

        return granted
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

    def get_applicable_roles_by_keys(keys)
      applicable_roles.slice(*Array(keys))
    end

    def roles_that_can(action, subject)
      applicable_roles.reject do |_, role|
        role.find_permission(action, subject).nil?
      end.keys
    end

    # Look up a stored scope block and call with the
    # current user and class
    def scope_for(action, klass, roles: nil)
      roles_to_check(roles: roles).each do |_, role|
        next if role.nil?

        permission = role.find_permission(action, klass)
        scope = permission&.fetch(user, klass, action)

        next if permission.nil? || (scope.nil? && fallthrough)

        return scope
      end

      @default_scope || nil
    end
    alias query scope_for

    # Fetch roles that apply to the current user
    def applicable_roles
      @applicable_roles ||= roles.select do |_, role|
        role.applies_to?(user)
      end
    end

    private

    def roles_to_check(roles: nil)
      roles.nil? ? applicable_roles : get_applicable_roles_by_keys(roles)
    end

    def permission_granted?(permission, action, subject)
      if fallthrough
        permission.nil? ? false : permission.granted?(user, subject, action)
      else
        permission.nil? ? nil : permission.granted?(user, subject, action)
      end
    end

    def get_proxied_permission(permission, action, subject, role)
      # Get proxied subject
      subject = subject.is_a?(Class) ? permission.granting_class : permission.granted_by.call(user, subject)

      # Get proxied permission
      permission = role.find_permission(action, subject)

      [subject, permission]
    end
  end
end
