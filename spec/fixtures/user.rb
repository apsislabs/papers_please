# frozen_string_literal: true

class User
  attr_accessor :posts, :admin, :manager, :member

  def initialize(posts:, admin: false, manager: false, member: false)
    @posts = posts
    @admin = admin
    @manager = manager
    @member = member
  end

  alias_method :admin?, :admin
  alias_method :manager?, :manager
  alias_method :member?, :member
end
