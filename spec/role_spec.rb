# frozen_string_literal: true

require "spec_helper"

RSpec.describe PapersPlease::Role do
  let(:admin_user) { User.new(posts: [], admin: true) }
  let(:manager_user) { User.new(posts: [], manager: true) }
  let(:member_user) { User.new(posts: [], member: true) }

  describe "#applies_to?" do
    context "with no predicate" do
      let(:no_predicate_role) { described_class.new(:admin) }

      it "applies" do
        expect(no_predicate_role.applies_to?(member_user)).to be true
      end
    end

    context "with predicate" do
      let(:admin_role) { described_class.new(:admin, predicate: proc { |user| user.admin? }) }

      it "applies to admin" do
        expect(admin_role.applies_to?(admin_user)).to be true
      end

      it "does not apply to member" do
        expect(admin_role.applies_to?(member_user)).to be false
      end
    end
  end

  describe "#add_permission" do
    context "manage is treated as a literal action" do
      let(:role) { described_class.new(:admin) }

      it "does not expand :manage" do
        role.add_permission(:manage, Post, allow_all: true)
        expect(role.permissions.size).to eq 1
        expect(role.permissions.first.key).to eq(:manage)
      end
    end

    context "duplicate permissions" do
      let(:role) { described_class.new(:admin) }

      it "raises error for duplicates" do
        role.add_permission(:read, Post, allow_all: true)
        expect { role.add_permission(:read, Post, allow_all: true) }.to raise_error(PapersPlease::DuplicatePermission)
      end
    end

    context "granted_by" do
      let(:resolver) { proc { |_u, a| a.post } }
      let(:granting_class) { Post }
      let(:role) { described_class.new(:admin) }

      it "raises exceptions for invalid grants" do
        expect do
          role.add_permission(:read, Attachment, granted_by: "invalid")
        end.to raise_error PapersPlease::InvalidGrant
        expect do
          role.add_permission(:read, Attachment, granted_by: resolver)
        end.to raise_error PapersPlease::InvalidGrant
        expect do
          role.add_permission(:read, Attachment, granted_by: granting_class)
        end.to raise_error PapersPlease::InvalidGrant
        expect { role.add_permission(:read, Attachment, granted_by: []) }.to raise_error PapersPlease::InvalidGrant
        expect do
          role.add_permission(:read, Attachment,
            granted_by: [resolver, granting_class])
        end.to raise_error PapersPlease::InvalidGrant

        expect { role.add_permission(:read, Attachment, granted_by: [granting_class, resolver]) }.not_to raise_error
      end

      it "adds a delegated permission without synthesizing standalone allow-all checks" do
        role.add_permission(:read, Attachment, granted_by: [granting_class, resolver])
        expect(role.permissions.size).to eq 1
        permission = role.permissions.first
        expect(permission.delegated?).to be true
        expect(permission.delegation.resolver).to eq resolver
        expect(permission.granting_class).to eq granting_class
        expect(permission.query).to be_nil
        expect(permission.predicate).to be_nil
      end
    end

    context "query and predicate" do
      let(:predicate) { proc { |user| user.admin? } }
      let(:query) { proc { [] } }
      let(:role) { described_class.new(:admin) }

      it "raises for non-callable query or predicate values" do
        expect { role.add_permission(:read, Post, query: "invalid") }.to raise_error(ArgumentError)
        expect { role.add_permission(:read, Post, predicate: "invalid") }.to raise_error(ArgumentError)
      end

      it "has correct query" do
        role.add_permission(:read, Post, query: query, predicate: predicate)
        expect(role.permissions.size).to eq 1
        expect(role.permissions.first.query).to be query
      end

      it "has correct predicate" do
        role.add_permission(:read, Post, query: query, predicate: predicate)
        expect(role.permissions.size).to eq 1
        expect(role.permissions.first.predicate).to be predicate
      end
    end

    context "only query" do
      let(:included_post) { Post.new }
      let(:excluded_post) { Post.new }
      let(:query) { proc { [included_post] } }
      let(:admin_role) { described_class.new(:admin) }
      let(:manager_role) { described_class.new(:manager) }

      it "has correct query" do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.query).to be query
        expect(admin_role.permissions.first.query.call).to contain_exactly(included_post)
      end

      it "generates predicate that allows posts in scope" do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, included_post)).to be true
      end

      it "generates predicate that disallows posts not in scope" do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, excluded_post)).to be false
      end

      it "generates predicate that disallows global access" do
        admin_role.add_permission(:read, Post, query: query)
        expect(admin_role.permissions.size).to eq 1
        expect(admin_role.permissions.first.predicate.call(admin_user, Post)).to be false
      end

      it "does not trust arbitrary scope objects with include?" do
        evil_scope = Class.new do
          def include?(_obj)
            true
          end
        end.new

        admin_role.add_permission(:read, Post, query: proc { evil_scope })

        expect(admin_role.permissions.first.predicate.call(admin_user, included_post)).to be false
      end

      it "uses exists? for ActiveRecord-like scopes" do
        relation = double("Relation")
        allow(relation).to receive(:exists?).with(123).and_return(true)
        allow(included_post).to receive(:id).and_return(123)

        admin_role.add_permission(:read, Post, query: proc { relation })

        expect(admin_role.permissions.first.predicate.call(admin_user, included_post)).to be true
      end

      it "supports Set scopes" do
        admin_role.add_permission(:read, Post, query: proc { Set[included_post] })

        expect(admin_role.permissions.first.predicate.call(admin_user, included_post)).to be true
        expect(admin_role.permissions.first.predicate.call(admin_user, excluded_post)).to be false
      end
    end

    context "only predicate" do
      let(:predicate) { proc { |user| user.admin? } }
      let(:predicate_role) { described_class.new(:admin) }

      it "has nil query" do
        predicate_role.add_permission(:read, Post, predicate: predicate)
        expect(predicate_role.permissions.size).to eq 1
        expect(predicate_role.permissions.first.query).to be_nil
      end

      it "has correct predicate" do
        predicate_role.add_permission(:read, Post, predicate: predicate)
        expect(predicate_role.permissions.size).to eq 1
        expect(predicate_role.permissions.first.predicate).to be predicate
      end
    end

    context "neither query nor predicate" do
      let(:empty_role) { described_class.new(:admin) }
      let(:klass) { spy("klass") }

      it "warns about implicit unconditional grants" do
        expect do
          empty_role.add_permission(:read, klass)
        end.to output(/grants unconditional access/).to_stderr
      end

      it "creates an all query when explicitly allowed" do
        empty_role.add_permission(:read, klass, allow_all: true)
        expect(empty_role.permissions.size).to eq 1

        empty_role.permissions.first.query.call
        expect(klass).to have_received(:all)
      end

      it "creates a true predicate when explicitly allowed" do
        empty_role.add_permission(:read, klass, allow_all: true)
        expect(empty_role.permissions.first.predicate.call).to be true
      end
    end
  end
end
