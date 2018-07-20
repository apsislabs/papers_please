module PapersPlease
  class Scope
    attr_reader :action, :klass, :actions, :prc, :config

    # rubocop:disable Metrics/ParameterLists
    def initialize(action, klass, prc, user = nil, actions = [], config = {})
      @action     = action
      @klass      = klass
      @prc        = prc
      @user       = user
      @actions    = actions
      @config     = config
    end
    # rubocop:enable Metrics/ParameterLists

    def matches_action?(action)
      @action == action
    end

    def matches_klass?(klass)
      klass == @klass
    end
  end
end
