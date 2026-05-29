# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Keyword aliases" do
  let(:user) { User.new(posts: [post], admin: true) }
  let(:post) { Post.new }
  let(:other_post) { Post.new }
  let(:scope_proc) { proc { |u| u.posts } }
  let(:if_proc) { proc { |_u, p| p == post } }

  describe "scope: aliases query:" do
    let(:role) { PapersPlease::Role.new(:test) }

    it "works with scope:" do
      role.grant :read, Post, scope: scope_proc
      permission = role.find_permission(:read, post)

      expect(permission.scope).to eq scope_proc
      expect(permission.query).to eq scope_proc
      expect(permission.granted?(user, post)).to be true
      expect(permission.granted?(user, other_post)).to be false
    end

    it "works with query:" do
      role.grant :read, Post, query: scope_proc
      permission = role.find_permission(:read, post)

      expect(permission.scope).to eq scope_proc
      expect(permission.query).to eq scope_proc
    end

    it "raises when both are passed" do
      expect {
        role.grant :read, Post, scope: scope_proc, query: scope_proc
      }.to raise_error(ArgumentError, /cannot pass both/)
    end
  end

  describe "if: aliases predicate:" do
    let(:role) { PapersPlease::Role.new(:test) }

    it "works with if:" do
      role.grant :read, Post, if: if_proc
      permission = role.find_permission(:read, post)

      expect(permission.predicate).to eq if_proc
      expect(permission.granted?(user, post)).to be true
      expect(permission.granted?(user, other_post)).to be false
    end

    it "works with predicate:" do
      role.grant :read, Post, predicate: if_proc
      permission = role.find_permission(:read, post)

      expect(permission.predicate).to eq if_proc
    end

    it "raises when both are passed" do
      expect {
        role.grant :read, Post, if: if_proc, predicate: if_proc
      }.to raise_error(ArgumentError, /cannot pass both/)
    end
  end

  describe "through: aliases granted_by:" do
    let(:role) { PapersPlease::Role.new(:test) }
    let(:grant_tuple) { [Post, proc { |_u, a| a.post }] }

    it "works with through:" do
      role.grant :read, Attachment, through: grant_tuple
      permission = role.find_permission(:read, Attachment.new(post: post))

      expect(permission.granted_by_other?).to be true
    end

    it "works with granted_by:" do
      role.grant :read, Attachment, granted_by: grant_tuple
      permission = role.find_permission(:read, Attachment.new(post: post))

      expect(permission.granted_by_other?).to be true
    end

    it "raises when both are passed" do
      expect {
        role.grant :read, Attachment, through: grant_tuple, granted_by: grant_tuple
      }.to raise_error(ArgumentError, /cannot pass both/)
    end
  end
end
