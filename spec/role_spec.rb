require 'spec_helper'

RSpec.describe PapersPlease::Role do
  let(:admin_user) { User.new(posts: [], admin: true) }
  let(:manager_user) { User.new(posts: [], manager: true) }
  let(:member_user) { User.new(posts: [], member: true) }

  describe '#applies_to?' do
    context 'with no predicate' do
      let(:no_predicate_role) { PapersPlease::Role.new(:admin) }
      it 'applies' do
        expect(no_predicate_role.applies_to?(member_user)).to be true
      end
    end

    context 'with predicate' do
      let(:admin_role) { PapersPlease::Role.new(:admin, predicate: (proc { |user| user.admin? })) }

      it 'applies to admin' do
        expect(admin_role.applies_to?(admin_user)).to be true
      end

      it 'does not apply to member' do
        expect(admin_role.applies_to?(member_user)).to be false
      end
    end
  end

  describe '#add_permission' do
    context 'manage expansion' do
      let (:role) { PapersPlease::Role.new(:admin) }

      it 'adds correct permissions' do
        role.add_permission(:manage, Post)
        expect(role.permissions.size).to eq 4

        permission_actions = role.permissions.map(&:key)
        expect(permission_actions).to contain_exactly(:create, :read, :update, :destroy)
      end
    end

    context 'duplicate permissions' do
      let (:role) { PapersPlease::Role.new(:admin) }

      it 'raises error for duplicates' do
        role.add_permission(:read, Post)
        expect { role.add_permission(:read, Post) }.to raise_error(PapersPlease::DuplicatePermission)
      end

      it 'raises error for duplicates in expansions' do
        role.add_permission(:read, Post)
        expect { role.add_permission(:manage, Post) }.to raise_error(PapersPlease::DuplicatePermission)
      end
    end

    context 'query and predicate' do
      let (:predicate) { (proc { |user| user.admin? }) }
      let (:query) { (proc { [] }) }
      let (:role) { PapersPlease::Role.new(:admin) }

      it 'has correct query' do
        role.add_permission(:read, Post, query: query, predicate: predicate)
        expect(role.permissions.size).to eq 1
        expect(role.permissions.first.query).to be query
      end

      it 'has correct predicate' do
        role.add_permission(:read, Post, query: query, predicate: predicate)
        expect(role.permissions.size).to eq 1
        expect(role.permissions.first.predicate).to be predicate
      end
    end

    context 'only query' do
      let (:included_post) { Post.new }
      let (:excluded_post) { Post.new }
      let (:query) { (proc { [included_post] }) }
      let (:admin_role) { PapersPlease::Role.new(:admin) }
      let (:manager_role) { PapersPlease::Role.new(:manager) }

      it 'has correct query' do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.query).to be query
        expect(admin_role.permissions.first.query.call).to contain_exactly(included_post)
      end

      it 'generates predicate that allows posts in scope' do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, included_post)).to be true
      end

      it 'generates predicate that disallows posts not in scope' do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, excluded_post)).to be false
      end

      it 'generates predicate that disallows global access' do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, Post)).to be false
      end

      # it 'generates a default true for :manage' do
      #     manager_role.add_permission(:manage, Post, query: query)
      #     expect(manager_role.permissions.size).to eq 4
      #     expect(manager_role.permissions.first.predicate.call(manager_user, Post)).to be true
      # end
    end

    context 'only predicate' do
      let (:predicate) { (proc { |user| user.admin? }) }
      let (:predicate_role) { PapersPlease::Role.new(:admin) }

      it 'has nil query' do
        predicate_role.add_permission(:read, Post, predicate: predicate)
        expect(predicate_role.permissions.size).to eq 1
        expect(predicate_role.permissions.first.query).to be_nil
      end

      it 'has correct predicate' do
        predicate_role.add_permission(:read, Post, predicate: predicate)
        expect(predicate_role.permissions.size).to eq 1
        expect(predicate_role.permissions.first.predicate).to be predicate
      end
    end

    context 'neither query nor predicate' do
      let (:empty_role) { PapersPlease::Role.new(:admin) }
      let (:klass) { spy('klass') }

      it 'creates an all query' do
        empty_role.add_permission(:read, klass)
        expect(empty_role.permissions.size).to eq 1

        empty_role.permissions.first.query.call
        expect(klass).to have_received(:all)
      end

      it 'creates a true predicate' do
        empty_role.add_permission(:read, klass)
        expect(empty_role.permissions.first.predicate.call).to be true
      end
    end
  end
end
