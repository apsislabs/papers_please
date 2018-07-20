module PapersPlease
  class Role
    attr_reader :name, :predicate, :permissions, :scopes

    def initialize(name, predicate: nil, definition: nil)
      @name = name
      @predicate = predicate
      @permissions = []
      @scopes = []

      instance_eval(&definition)
    end

    def applies_to?(user)
      if @predicate.is_a? Proc
        @predicate.call(user)
      else
        true
      end
    end

    # Shorthand for calling add_scope and add_permission,
    # where the add_permission call is a check for
    # inclusion in the relation from the add_scope call
    def grant(action, klass, &block)
      prepare_actions(action).each do |a|
        if block_given?
          add_scope a, klass, &block

          add_permission a, klass do |u, obj|
            scope = find_scope(a, klass)
            scope.call(a, u, klass).include?(obj)
          end
        else
          add_scope a, klass { klass.all }
          can a, klass
        end
      end
    end

    # Permissions

    # Store a block referenced by an symbol and klass
    # this block should return true or false
    def add_permission(action, klass, &block)
      prepare_actions(action).each do |a|
        raise DuplicatePermission if permission_exists?(a, subject)
        permissions << Permission.new(a, klass, block)
      end
    end
    alias can add_permission

    def find_permission(action, subject)
      permissions.detect do |permission|
        permission.action == action &&
          permission.subject == subject
      end
    end

    def permission_exists?(action, subject)
      !!find_permission(action, subject)
    end

    # Scopes

    # Store a block referenced by an symbol and klass
    # this block should return an ActiveRecord::Relation
    def add_scope(action, klass, &block)
      prepare_actions(action).each do |a|
        raise DuplicateScope if scope_exists?(a, subject)
        scopes << Scope.new(a, klass, block)
      end
    end
    alias scope add_scope

    def find_scope(action, subject)
      scopes.detect do |scope|
        scope.action == action &&
          scope.subject == subject
      end
    end

    def scope_exists?(action, subject)
      !!find_scope(action, subject)
    end

    private

    # Wrap actions, translating :manage into :crud
    def prepare_actions(action)
      Array(*[action]).flat_map do |a|
        a == :manage ? [:create, :read, :update, :destroy] : [a]
      end
    end
  end
end
