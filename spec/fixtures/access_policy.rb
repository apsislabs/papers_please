class AccessPolicy < PapersPlease::Policy
  def configure
    role :admin, (proc { |user| user.admin? })
    role :member, (proc { |user| user.member? })

    permit :admin do |role|
      role.grant :manage, Post
    end

    permit :member do |role|
      role.grant :create, Post
      role.grant [:read, :update], Post, query: (proc { |u| u.posts })
    end
  end
end
