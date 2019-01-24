class User
  attr_accessor :posts, :admin, :manager, :member

  def initialize(posts:, admin: false, manager: false, member: false)
    @posts = posts
    @admin = admin
    @manager = manager
    @member = member
  end

  alias admin? admin
  alias manager? manager
  alias member? member
end
