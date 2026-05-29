# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Collection permissions" do
  let(:user) { User.new(posts: [post], admin: true) }
  let(:post) { Post.new }
  let(:scope_proc) { proc { |u| u.posts } }

  describe "collection: true" do
    let(:role) { PapersPlease::Role.new(:test) }

    it "auto-predicate allows the class" do
      role.grant :index, Post, collection: true, scope: scope_proc
      permission = role.find_permission(:index, Post)

      expect(permission.collection?).to be true
      expect(permission.granted?(user, Post)).to be true
    end

    it "scope still works for scoping" do
      role.grant :index, Post, collection: true, scope: scope_proc
      permission = role.find_permission(:index, Post)

      expect(permission.fetch(user, Post)).to contain_exactly(post)
    end

    it "explicit if: overrides collection auto-predicate" do
      role.grant :index, Post, collection: true, scope: scope_proc, if: proc { false }
      permission = role.find_permission(:index, Post)

      expect(permission.granted?(user, Post)).to be false
    end

    it "works without a scope" do
      role.grant :create, Post, collection: true, allow_all: true
      permission = role.find_permission(:create, Post)

      expect(permission.collection?).to be true
      expect(permission.granted?(user, Post)).to be true
    end
  end

  describe "collection: false (default)" do
    let(:role) { PapersPlease::Role.new(:test) }

    it "auto-predicate checks inclusion" do
      role.grant :show, Post, scope: scope_proc
      permission = role.find_permission(:show, post)

      expect(permission.collection?).to be false
      expect(permission.granted?(user, post)).to be true
    end

    it "auto-predicate rejects non-included instances" do
      role.grant :show, Post, scope: scope_proc

      other = Post.new
      expect(role.find_permission(:show, other).granted?(user, other)).to be false
    end

    it "auto-predicate rejects the class itself" do
      role.grant :show, Post, scope: scope_proc

      expect(role.find_permission(:show, Post).granted?(user, Post)).to be false
    end
  end
end
