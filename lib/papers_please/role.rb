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
      scope, predicate, through, collection, allow_all = resolve_opts(opts)

      Array(actions).each do |action|
        raise DuplicatePermission if permission_exists?(action, klass)

        warn_unconditional_grant(action, klass) if scope.nil? && predicate.nil? && through.nil? && !allow_all

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
      allow_all = opts.fetch(:allow_all, false)

      [scope, predicate, through, collection, allow_all]
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

      Delegation.new(klass: through[0], resolver: through[1])
    end

    def valid_delegation?(tuple)
      tuple.is_a?(Array) && tuple.length == 2 && tuple[0].is_a?(Class) && tuple[1].is_a?(Proc)
    end

    def warn_unconditional_grant(action, klass)
      warn "[papers_please] role.grant #{action.inspect}, #{klass.inspect} grants unconditional access. " \
        "Pass if:/scope: or allow_all: true to make this explicit."
    end

    def make_permission(action, klass, scope: nil, predicate: nil, delegation: nil, collection: false)
      has_scope = !scope.nil?
      has_predicate = !predicate.nil?
      permission = Permission.new(action, klass, delegation: delegation, collection: collection)

      if has_scope && has_predicate
        permission.scope = scope
        permission.predicate = predicate
      elsif has_scope
        permission.scope = scope
        permission.predicate = collection ? (proc { |_u, _s| true }) : build_predicate_from_scope(klass, scope)
      elsif has_predicate
        permission.predicate = predicate
      else
        permission.scope = (proc { |_u, _k| klass.all })
        permission.predicate = (proc { |_u, _s| true })
      end

      permission
    end

    def build_predicate_from_scope(klass, scope)
      proc do |user, obj|
        if klass.is_a?(Class) && obj.is_a?(klass)
          res = scope.call(user, klass)

          if res.respond_to?(:exists?) && obj.respond_to?(:id)
            res.exists?(obj.id)
          elsif res.is_a?(Array)
            res.include?(obj)
          else
            false
          end
        else
          false
        end
      end
    end
  end
end
