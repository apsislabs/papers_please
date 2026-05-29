# frozen_string_literal: true

class AccessPolicy < PapersPlease::Policy
  def configure
    role :admin, proc { |user| user.admin? }
    role :manager, proc { |user| user.manager? }
    role :member, proc { |user| user.member? }

    permit :admin do |role|
      role.grant %i[create read update destroy], Post, allow_all: true
      role.grant %i[create read update destroy], Attachment, allow_all: true
    end

    permit :manager do |role|
      role.grant :create, Post, collection: true, allow_all: true
      role.grant %i[read update destroy], Post, query: proc { |u| u.posts }
      role.grant %i[create read update destroy], Attachment, granted_by: [Post, proc { |_u, a| a.post }]
    end

    permit :member do |role|
      role.grant :create, Post, collection: true, allow_all: true
      role.grant %i[read update], Post, query: proc { |u| u.posts }
      role.grant %i[create read update], Attachment, granted_by: [Post, proc { |_u, a| a.post }]
    end
  end
end
