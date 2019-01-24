module PapersPlease
  class Role
    attr_reader :name, :predicate, :permissions

    def initialize(name, predicate: nil, definition: nil)
      @name = name
      @predicate = predicate
      @permissions = []
    end

    def applies_to?(user)
      return @predicate.call(user) if @predicate.is_a? Proc

      true
    end

    def add_permission(actions, klass, query: nil, predicate: nil, granted_by: nil)
      prepare_actions(actions).each do |action|
        raise DuplicatePermission if permission_exists?(action, klass)
        raise InvalidGrant, 'granted_by must be an array of [Class, Proc]' if !granted_by.nil? && !valid_grant?(granted_by)

        has_query = query.is_a?(Proc)
        has_predicate = predicate.is_a?(Proc)
        permission = Permission.new(action, klass)

        if granted_by
          permission.granting_class = granted_by[0]
          permission.granted_by = granted_by[1]
        end

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
              res = query.call(user, klass, action)
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

    def valid_grant?(tuple)
      return false unless tuple.is_a? Array
      return false unless tuple.length == 2
      return false unless tuple[0].is_a? Class
      return false unless tuple[1].is_a? Proc

      return true
    end

    # Wrap actions, translating :manage into :crud
    def prepare_actions(action)
      Array(action).flat_map do |a|
        a == :manage ? %i[create read update destroy] : [a]
      end
    end
  end
end
