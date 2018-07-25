module PapersPlease
  class Role
    attr_reader :name, :predicate, :permissions

    def initialize(name, predicate: nil, definition: nil)
      @name = name
      @predicate = predicate
      @permissions = []

      instance_eval(&definition) unless definition.nil?
    end

    def applies_to?(user)
      return @predicate.call(user) if @predicate.is_a? Proc
      true
    end

    def add_permission(actions, klass, query: nil, predicate: nil)
      prepare_actions(actions).each do |action|
        raise DuplicatePermission if permission_exists?(action, klass)

        has_query = query.is_a?(Proc)
        has_predicate = predicate.is_a?(Proc)
        permission = Permission.new(action, klass)

        if has_query && has_predicate
          # Both query & predicate provided

          permission.query = query
          permission.predicate = predicate
        elsif has_query && !has_predicate
          # Only query provided

          permission.query = query

          if action == :create && actions == :manage
            # If the action is :create, expanded from :manage
            # then we set the default all predicate
            permission.predicate = (proc { true })
          else
            # Otherwise the default predicate is to check
            # for inclusion in the returned relationship
            permission.predicate = (proc { |user, obj|
              puts "user #{user.inspect}"
              res = query.call(user, klass, action)
              puts "query result: #{res.inspect}"
              res.respond_to?(:include?) && res.include?(obj)
            })
          end
        elsif !has_query && has_predicate
          # Only predicate provided

          permission.predicate = predicate
        else
          # Neither provided
          permission.query = (proc { klass.all })
          permission.predicate = (proc { true })
        end

        permissions << permission
      end
    end
    alias grant add_permission

    def find_permission(action, subject)
      permissions.detect do |permission|
        permission.matches? action, subject
      end
    end

    def permission_exists?(action, subject)
      !find_permission(action, subject).nil?
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
