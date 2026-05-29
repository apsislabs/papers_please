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
      return Callable.call(@predicate, user) if @predicate.is_a?(Proc)

      true
    end

    def add_permission(actions, klass, **opts)
      scope, predicate, through, collection = resolve_opts(opts)

      Array(actions).each do |action|
        raise DuplicatePermission if permission_exists?(action, klass)

        delegation = build_delegation(through)

        permissions << make_permission(
          action, klass,
          scope: scope, predicate: predicate, delegation: delegation, collection: collection
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
      through = resolve_alias(opts, :through, :granted_by)
      collection = opts.fetch(:collection, false)

      [scope, predicate, through, collection]
    end

    def resolve_alias(opts, new_name, old_name)
      has_new = opts.key?(new_name)
      has_old = opts.key?(old_name)

      if has_new && has_old
        raise ArgumentError, "cannot pass both :#{new_name} and :#{old_name}"
      end

      has_new ? opts[new_name] : opts[old_name]
    end

    def build_delegation(through)
      return nil if through.nil?

      raise InvalidGrant, "through must be a [Class, Proc], got #{through.inspect}" unless valid_delegation?(through)

      Delegation.new(through[0], through[1])
    end

    def valid_delegation?(tuple)
      tuple.is_a?(Array) && tuple.length == 2 && tuple[0].is_a?(Class) && tuple[1].is_a?(Proc)
    end

    def make_permission(action, klass, scope: nil, predicate: nil, delegation: nil, collection: false)
      has_scope = scope.is_a?(Proc)
      has_predicate = predicate.is_a?(Proc)
      permission = Permission.new(action, klass, delegation: delegation, collection: collection)

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

    def build_predicate_from_scope(klass, scope)
      proc do |user, obj|
        res = Callable.call(scope, user, klass)
        res.respond_to?(:include?) && res.include?(obj)
      end
    end
  end
end
