class AccessPolicy < PapersPlease::Policy
  def configure
    role :admin, (proc { |user| user.admin? }) do
      grant :manage, Post
    end

    role :member, (proc { |user| user.member? }) do
      grant :create, Post
      grant [:read, :update], Post, query: (proc { |u| u.posts })
    end
  end
end
