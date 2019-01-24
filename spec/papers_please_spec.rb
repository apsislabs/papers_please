RSpec.describe PapersPlease do
  it 'has a version number' do
    expect(PapersPlease::VERSION).not_to be nil
  end

  context 'access policy' do
    let(:posts) { Array.new(5) { Post.new } }
    let(:post) { posts.first }
    let(:attachment) { Attachment.new(post: post) }
    let(:restricted_post) { posts.last }
    let(:restricted_attachment) { Attachment.new(post: restricted_post) }
    let(:other_post) { Post.new }

    let(:member) { User.new(posts: posts.slice(0, 3), member: true) }
    let(:manager) { User.new(posts: posts.slice(0, 3), manager: true) }
    let(:admin) { User.new(posts: posts, admin: true) }

    context 'admin' do
      before(:each) { @policy = AccessPolicy.new(admin) }

      describe '#can?' do
        it 'grants permissions' do
          # Posts
          expect(@policy.can?(:create, Post)).to be true
          expect(@policy.can?(:read, post)).to be true
          expect(@policy.can?(:update, post)).to be true
          expect(@policy.can?(:destroy, post)).to be true
          expect(@policy.can?(:read, restricted_post)).to be true
          expect(@policy.can?(:update, restricted_post)).to be true
          expect(@policy.can?(:destroy, restricted_post)).to be true
          expect(@policy.can?(:tomato, Post)).to be false
        end
      end

      describe '#scope_for' do
        it 'creates scope correctly' do
          expect(@policy.scope_for(:read, Post)).to contain_exactly(*Post.all)
        end
      end

      describe '#authorize!' do
        it 'raises exception if not allowed' do
          expect { @policy.authorize! :not_real, Post }.to(raise_exception { PapersPlease::AccessDenied })
          expect { @policy.authorize! :not_real, post }.to(raise_exception { PapersPlease::AccessDenied })
        end

        it 'does nothing if allowed' do
          expect { @policy.authorize! :create, Post }.not_to raise_exception
          expect { @policy.authorize! :read, post }.not_to raise_exception
        end
      end
    end

    context 'manager' do
      before(:each) { @policy = AccessPolicy.new(manager) }

      describe '#can?' do
        describe '#can?' do
          it 'grants permissions' do
            # Post
            expect(@policy.can?(:create, Post)).to be true
            expect(@policy.can?(:read, post)).to be true
            expect(@policy.can?(:update, post)).to be true
            expect(@policy.can?(:destroy, post)).to be true

            expect(@policy.can?(:read, restricted_post)).to be false
            expect(@policy.can?(:update, restricted_post)).to be false
            expect(@policy.can?(:destroy, restricted_post)).to be false

            # Attachments
            expect(@policy.can?(:create, Attachment)).to be true
            expect(@policy.can?(:read, attachment)).to be true
            expect(@policy.can?(:update, attachment)).to be true
            expect(@policy.can?(:destroy, attachment)).to be true

            expect(@policy.can?(:read, restricted_attachment)).to be false
            expect(@policy.can?(:update, restricted_attachment)).to be false
            expect(@policy.can?(:destroy, restricted_attachment)).to be false

            # Invalid
            expect(@policy.can?(:read, Post)).to be false
            expect(@policy.can?(:read, Attachment)).to be false
            expect(@policy.can?(:tomato, Post)).to be false
          end
        end
      end

      describe '#scope_for' do
        it 'creates scope correctly' do
          expect(@policy.scope_for(:read, Post)).to contain_exactly(*manager.posts)
          expect(@policy.scope_for(:update, Post)).to contain_exactly(*manager.posts)
          expect(@policy.scope_for(:destroy, Post)).to contain_exactly(*manager.posts)
        end
      end

      describe '#authorize!' do
        it 'raises exception if not allowed' do
          expect { @policy.authorize! :read, restricted_post }.to(raise_exception { PapersPlease::AccessDenied })
          expect { @policy.authorize! :destroy, restricted_post }.to(raise_exception { PapersPlease::AccessDenied })
        end

        it 'does nothing if allowed' do
          expect { @policy.authorize! :create, Post }.not_to raise_exception
          expect { @policy.authorize! :read, post }.not_to raise_exception
        end
      end
    end

    context 'member' do
      before(:each) { @policy = AccessPolicy.new(member) }

      describe '#can?' do
        it 'grants permissions correctly' do
          # Posts
          expect(@policy.can?(:create, Post)).to be true
          expect(@policy.can?(:read, post)).to be true
          expect(@policy.can?(:update, post)).to be true
          expect(@policy.can?(:destroy, post)).to be false
          expect(@policy.can?(:read, restricted_post)).to be false
          expect(@policy.can?(:update, restricted_post)).to be false
          expect(@policy.can?(:destroy, restricted_post)).to be false

          # Attachments
          expect(@policy.can?(:create, Attachment)).to be true
          expect(@policy.can?(:read, attachment)).to be true
          expect(@policy.can?(:update, attachment)).to be true
          expect(@policy.can?(:destroy, attachment)).to be false

          expect(@policy.can?(:read, restricted_attachment)).to be false
          expect(@policy.can?(:update, restricted_attachment)).to be false
          expect(@policy.can?(:destroy, restricted_attachment)).to be false

          expect(@policy.can?(:read, Post)).to be false
          expect(@policy.can?(:read, Attachment)).to be false
          expect(@policy.can?(:tomato, Post)).to be false
        end
      end

      describe '#scope_for' do
        it 'creates scope correctly' do
          expect(@policy.scope_for(:read, Post)).to contain_exactly(*member.posts)
        end
      end

      describe '#authorize!' do
        it 'raises exception if not allowed' do
          expect { @policy.authorize! :destroy, Post }.to(raise_exception { PapersPlease::AccessDenied })
          expect { @policy.authorize! :destroy, post }.to(raise_exception { PapersPlease::AccessDenied })
        end

        it 'does nothing if allowed' do
          expect { @policy.authorize! :create, Post }.not_to raise_exception
          expect { @policy.authorize! :read, post }.not_to raise_exception
        end
      end
    end
  end
end
