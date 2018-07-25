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
      klass = Class.new(PapersPlease::Policy)
      expect { klass.new(member) }.to raise_error(NotImplementedError)
    end

    context 'predicate check' do
      before(:each) do
        allow(owner_member).to receive(:spy_method)
        allow(post).to receive(:spy_method)
      end

      it 'passes user and object to permission check' do
        klass = Class.new(PapersPlease::Policy) do
          def configure
            role :member do
              grant :read, Post, predicate: (proc { |u, p| u.spy_method; p.spy_method })
            end
          end
        end

        klass.new(owner_member).can?(:read, post)
        expect(owner_member).to have_received(:spy_method)
        expect(post).to have_received(:spy_method)
      end
    end

    context 'query' do
      before(:each) do
        allow(owner_member).to receive(:spy_method)
        allow(Post).to receive(:spy_method)
      end

      it 'passes user and class to scope' do
        klass = Class.new(PapersPlease::Policy) do
          def configure
            role :member do
              grant :read, Post, query: (proc { |u, p| u.spy_method; p.spy_method })
            end
          end
        end

        klass.new(owner_member).scope_for(:read, Post)
        expect(owner_member).to have_received(:spy_method)
        expect(Post).to have_received(:spy_method)
      end
    end
  end
end
