class AccessPolicy < PapersPlease::Policy
  def configure
    role :admin, (proc { |user| user.admin? })
    role :manager, (proc { |user| user.manager? })
    role :member, (proc { |user| user.member? })

    permit :admin do |role|
      role.grant :manage, Post
      role.grant :manage, Attachment
    end

    permit :manager do |role|
      role.grant :manage, Post, query: (proc { |u| u.posts })
      role.grant :manage, Attachment, granted_by: [Post, (proc { |_u, a| a.post })]
    end

    permit :member do |role|
      role.grant :create, Post
      role.grant %i[read update], Post, query: (proc { |u| u.posts })
      role.grant %i[create read update], Attachment, granted_by: [Post, (proc { |_u, a| a.post })]
    end
  end
end
