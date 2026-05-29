# frozen_string_literal: true

module PapersPlease
  class Role
    attr_reader :name, :predicate, :permissions

    def initialize(name, predicate: nil)
      @name = name
      @predicate = predicate
      @permissions = []
    end

    def applies_to?(user)
      return @predicate.call(user) if @predicate.is_a?(Proc)

      true
    end

    def add_permission(actions, klass, **opts)
      scope, predicate, granted_by, collection = resolve_opts(opts)

      Array(actions).each do |action|
        raise DuplicatePermission if permission_exists?(action, klass)

        if !granted_by.nil? && !valid_grant?(granted_by)
          raise InvalidGrant,
            "granted_by must be an array of [Class, Proc]"
        end

        permissions << make_permission(
          action, klass,
          scope: scope, predicate: predicate, granted_by: granted_by, collection: collection
        )
      end
    end
    alias_method :grant, :add_permission

    def find_permission(action, subject)
      permissions.detect do |permission|
        permission.matches? action, subject
      end
    end

    def permission_exists?(action, subject)
      !find_permission(action, subject).nil?
    end

    private

    def resolve_opts(opts)
      scope = resolve_alias(opts, :scope, :query)
      predicate = resolve_alias(opts, :if, :predicate)
      granted_by = resolve_alias(opts, :through, :granted_by)
      collection = opts.fetch(:collection, false)

      [scope, predicate, granted_by, collection]
    end

    def resolve_alias(opts, new_name, old_name)
      has_new = opts.key?(new_name)
      has_old = opts.key?(old_name)

      if has_new && has_old
        raise ArgumentError, "cannot pass both :#{new_name} and :#{old_name}"
      end

      has_new ? opts[new_name] : opts[old_name]
    end

    def valid_grant?(tuple)
      return false unless tuple.is_a? Array
      return false unless tuple.length == 2
      return false unless tuple[0].is_a? Class
      return false unless tuple[1].is_a? Proc

      true
    end

    def make_permission(action, klass, scope: nil, predicate: nil, granted_by: nil, collection: false)
      has_scope = scope.is_a?(Proc)
      has_predicate = predicate.is_a?(Proc)
      permission = make_base_permission(action, klass, granted_by: granted_by, collection: collection)

      if has_scope && has_predicate
        permission.scope = scope
        permission.predicate = predicate
      elsif has_scope
        permission.scope = scope
        permission.predicate = collection ? (proc { true }) : build_predicate_from_scope(klass, scope)
      elsif has_predicate
        permission.predicate = predicate
      else
        permission.scope = (proc { klass.all })
        permission.predicate = (proc { true })
      end

      permission
    end

    def make_base_permission(action, klass, granted_by: nil, collection: false)
      permission = Permission.new(action, klass, collection: collection)

      if granted_by
        permission.granting_class = granted_by[0]
        permission.granted_by = granted_by[1]
      end

      permission
    end

    def build_predicate_from_scope(klass, scope)
      proc do |user, obj|
        res = scope.call(user, klass)
        res.respond_to?(:include?) && res.include?(obj)
      end
    end
  end
end
