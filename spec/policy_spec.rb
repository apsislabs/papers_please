# frozen_string_literal: true

RSpec.describe PapersPlease::Policy do
  let(:posts) { Array.new(5) { Post.new } }
  let(:post) { posts.first }
  let(:other_post) { Post.new }

  let(:member) { User.new(posts: posts.slice(0, 3), admin: false, member: true) }
  let(:admin) { User.new(posts: posts, admin: true, member: false) }

  describe '#configure' do
    let(:post) { Post.new }
    let(:owner_member) { User.new(posts: [post], member: true) }
    let(:other_member) { User.new(posts: [], member: true) }

    it 'raises not implemented if not overriden' do
      klass = Class.new(described_class)
      expect { klass.new(member) }.to raise_error(NotImplementedError)
    end

    context 'predicate check' do
      before do
        allow(owner_member).to receive(:spy_method)
        allow(post).to receive(:spy_method)
      end

      it 'passes user and object to permission check' do
        klass = Class.new(PapersPlease::Policy) do
          def configure
            role :member

            permit :member do |role|
              role.grant :read, Post, predicate: (proc { |u, p|
                                                    u.spy_method
                                                    p.spy_method
                                                  })
            end
          end
        end

        klass.new(owner_member).can?(:read, post)
        expect(owner_member).to have_received(:spy_method)
        expect(post).to have_received(:spy_method)
      end
    end

    context 'query' do
      before do
        allow(owner_member).to receive(:spy_method)
        allow(Post).to receive(:spy_method)
      end

      it 'passes user and class to scope' do
        klass = Class.new(PapersPlease::Policy) do
          def configure
            role :member

            permit :member do |role|
              role.grant :read, Post, query: (proc { |u, p|
                                                u.spy_method
                                                p.spy_method
                                              })
            end
          end
        end

        klass.new(owner_member).scope_for(:read, Post)
        expect(owner_member).to have_received(:spy_method)
        expect(Post).to have_received(:spy_method)
      end
    end
  end

  describe '#can' do
    it 'returns true for passing predicate' do
      policy = sample_policy(member)
      expect(policy.can?(:read, post)).to be true
    end

    it 'return false for failing predicate' do
      policy = sample_policy(member)
      expect(policy.can?(:read, posts.last)).to be false
    end

    context 'with fallthrough' do
      it 'returns true when any applicable role has a passing predicate' do
        # Only members can read this new post because it is published, but
        # does not belong to the admin
        new_post = Post.new
        new_post.published = true

        admin_policy = sample_fallthrough_policy(admin)

        expect(admin_policy.applicable_roles.keys).to contain_exactly(:admin, :member)
        expect(admin_policy.can?(:read, new_post)).to be true
        expect(admin_policy.can?(:read, posts.last)).to be true

        member_policy = sample_fallthrough_policy(member)
        expect(member_policy.applicable_roles.keys).to contain_exactly(:member)
        expect(member_policy.can?(:read, new_post)).to be true
        expect(member_policy.can?(:read, posts.last)).to be false
      end

      it 'returns false if no roles have a passing predicate' do
        # No one can read this post because it does not belong to the admin
        # and it is not published
        new_post = Post.new
        new_post.published = false

        admin_policy = sample_fallthrough_policy(admin)
        expect(admin_policy.can?(:read, new_post)).to be false

        member_policy = sample_fallthrough_policy(member)
        expect(member_policy.can?(:read, new_post)).to be false
      end
    end

    context 'with specific role check' do
      it 'allows you to specify a role to check against' do
        # Only members can read this new post because it is published, but
        # does not belong to the admin
        new_post = Post.new
        new_post.published = true

        admin_policy = sample_fallthrough_policy(admin)

        expect(admin_policy.applicable_roles.keys).to contain_exactly(:admin, :member)
        expect(admin_policy.can?(:read, new_post, roles: [:admin])).to be false
        expect(admin_policy.can?(:read, new_post, roles: [:member])).to be true
        expect(admin_policy.can?(:read, new_post)).to be true
      end
    end
  end

  describe '#role_that_can' do
    it 'returns the symbolic name of the roles that can perform an action' do
      policy_klass = Class.new(PapersPlease::Policy) do
        def configure
          role :member
          role :admin

          permit :admin do |role|
            role.grant :admin, Post
            role.grant :foo, Post
          end

          permit :member do |role|
            role.grant :read, Post
            role.grant :foo, Post
          end
        end
      end

      policy = policy_klass.new(admin)
      expect(policy.roles_that_can(:read, Post)).to contain_exactly(:member)
      expect(policy.roles_that_can(:admin, Post)).to contain_exactly(:admin)
      expect(policy.roles_that_can(:foo, Post)).to contain_exactly(:admin, :member)
    end
  end

  describe '#authorize!' do
    it 'raises an AccessDenied error for failing predicate' do
      policy = sample_policy(member)
      expect { policy.authorize! :read, posts.last }.to raise_error(PapersPlease::AccessDenied)
    end
  end

  private

  def sample_policy_klass
    Class.new(PapersPlease::Policy) do
      def configure
        role :admin, (proc { |u| u.admin })
        role :member, (proc { |u| u.member })

        permit :admin do |role|
          role.grant :read, Post
        end

        permit :member do |role|
          role.grant :read, Post, predicate: (proc { |u, p| u.posts.include? p })
        end
      end
    end
  end

  def sample_fallthrough_policy_klass
    Class.new(PapersPlease::Policy) do
      def configure
        allow_fallthrough

        role :member, (proc { |u| u.admin || u.member })
        role :admin, (proc { |u| u.admin })

        permit :admin do |role|
          role.grant :read, Post, predicate: (proc { |u, p| u.posts.include?(p) })
        end

        permit :member do |role|
          role.grant :read, Post, predicate: (proc { |_u, p| p.published })
        end
      end
    end
  end

  def sample_policy(user)
    sample_policy_klass.new(user)
  end

  def sample_fallthrough_policy(user)
    sample_fallthrough_policy_klass.new(user)
  end
end
