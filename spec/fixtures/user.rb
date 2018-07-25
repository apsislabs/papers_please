class User
  attr_accessor :posts, :admin, :member

  def initialize(posts:, admin: false, member: false)
    @posts = posts
    @admin = admin
    @member = member
  end

  alias admin? admin
  alias member? member
end
