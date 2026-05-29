# frozen_string_literal: true

module PapersPlease
  class Policy
    attr_reader :roles, :fallthrough, :user

    def initialize(user)
      @user = user
      @default_scope = nil
      @roles = {}

      configure
    end

    def allow_fallthrough
      @fallthrough = true
    end

    def default_scope(scope) # standard:disable Style/TrivialAccessors
      @default_scope = scope
    end

    def configure
      raise NotImplementedError, "The #configure method of the access policy was not implemented"
    end

    def add_role(name, klass_or_predicate = nil, predicate = nil)
      role_class, resolved_predicate = resolve_role_class_and_predicate(klass_or_predicate, predicate)
      name = name.to_sym
      raise DuplicateRole if roles.key?(name)

      role = role_class.new(name, predicate: resolved_predicate, user: user, policy: self)
      roles[name] = role

      role
    end
    alias_method :role, :add_role

    def add_permissions(keys)
      return unless block_given?

      Array(keys).each do |key|
        raise MissingRole unless roles.key?(key)

        yield roles[key]
      end
    end
    alias_method :permit, :add_permissions

    def can?(action, subject = nil, roles: nil)
      check_subject = subject

      roles_to_check(roles: roles).each do |_, role|
        permission = role&.find_permission(action, check_subject)
        next if permission.nil?

        granted = permission_granted_for_role?(role, permission, check_subject)
        next if !granted && fallthrough

        return granted
      end

      false
    end

    def cannot?(*args)
      !can?(*args)
    end

    def authorize!(action, subject)
      return subject if can?(action, subject)

      raise AccessDenied, "Access denied for #{action.inspect} on #{subject_label(subject)}"
    end

    def get_applicable_roles_by_keys(keys)
      applicable_roles.slice(*Array(keys))
    end

    def permitted_actions(subject)
      applicable_roles.each_with_object(Set.new) do |(_, role), actions|
        role.permissions.each do |permission|
          next unless permission.matches_subject?(subject)
          next if actions.include?(permission.key)
          next unless permission_granted_for_role?(role, permission, subject)

          actions << permission.key
        end
      end.to_a
    end

    def roles_that_can(action, subject)
      applicable_roles.filter do |_, role|
        permission = role.find_permission(action, subject)
        permission && permission_granted_for_role?(role, permission, subject)
      end.keys
    end

    def scope_for(action, klass, roles: nil)
      roles_to_check(roles: roles).each do |_, role|
        next if role.nil?

        permission = role.find_permission(action, klass)
        scope = permission&.fetch(user, klass)

        next if permission.nil? || (scope.nil? && fallthrough) # standard:disable Style/SafeNavigation

        return scope
      end

      @default_scope || nil
    end
    alias_method :query, :scope_for

    def applicable_roles
      @applicable_roles ||= roles.select do |_, role|
        role.applies_to?(user)
      end
    end

    private

    def roles_to_check(roles: nil)
      roles.nil? ? applicable_roles : get_applicable_roles_by_keys(roles)
    end

    def resolve_role_class_and_predicate(klass_or_predicate, predicate)
      if klass_or_predicate.is_a?(Class)
        unless klass_or_predicate <= Role
          raise ArgumentError, "role class must inherit from PapersPlease::Role"
        end

        [klass_or_predicate, predicate]
      else
        [Role, klass_or_predicate]
      end
    end

    def subject_label(subject)
      klass = Object.instance_method(:class).bind_call(subject)

      if klass == Class
        subject.name || "anonymous class"
      else
        klass.name || "anonymous #{klass}"
      end
    end

    def permission_granted_for_role?(role, permission, subject)
      resolved_subject = subject

      if permission.delegated?
        resolved_subject, permission = resolve_delegation(permission, subject, role)
        return false if permission.nil?
      end

      !!permission.granted?(user, resolved_subject)
    end

    def resolve_delegation(permission, subject, role)
      delegation = permission.delegation
      resolved = subject.is_a?(Class) ? delegation.klass : delegation.resolve(user, subject)
      # Delegation is intentionally same-role only: a delegated grant is an
      # indirection to another permission on the role that declared it, not a
      # search across every applicable role.
      permission = role.find_permission(permission.key, resolved)

      [resolved, permission]
    end
  end
end
