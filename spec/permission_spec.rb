# frozen_string_literal: true

require "spec_helper"

RSpec.describe PapersPlease::Permission do
  subject { described_class }

  let(:book) { double("Book") }
  let(:user) { double("User") }

  it "requires a key and subject" do
    expect { subject.new }.to raise_error(ArgumentError)
    expect { subject.new(:key) }.to raise_error(ArgumentError)
    expect { subject.new(:key, book) }.not_to raise_error
  end

  it "validates arguments" do
    expect { subject.new(:key, book, query: "invalid") }.to raise_error(ArgumentError)
    expect { subject.new(:key, book, predicate: "invalid") }.to raise_error(ArgumentError)
  end

  it "allows query and predicate" do
    stub_proc = proc { true }
    perm = subject.new(:key, book, predicate: stub_proc, query: stub_proc)

    expect(perm.predicate).to be stub_proc
    expect(perm.query).to be stub_proc
  end

  it "has immutable key, subject, collection, and delegation" do
    perm = subject.new(:key, book)

    expect(perm).not_to respond_to(:key=)
    expect(perm).not_to respond_to(:subject=)
    expect(perm).not_to respond_to(:collection=)
    expect(perm).not_to respond_to(:delegation=)
  end

  describe "#matches?" do
    let(:permission) { subject.new(:read, book) }

    it "matches" do
      expect(permission.matches?(:read, book)).to be true
    end

    it "does not match" do
      expect(permission.matches?(:write, book)).to be false
    end
  end

  describe "#matches_subject?" do
    let(:permission) { subject.new(:read, book) }

    it "matches the subject" do
      expect(permission.matches_subject?(book)).to be true
    end

    it "does not let runtime subjects spoof equality" do
      post_permission = subject.new(:read, Post)
      evil = Class.new do
        def ==(_other)
          true
        end
      end.new

      expect(post_permission.matches_subject?(evil)).to be false
    end

    it "matches class subjects and subclasses" do
      subclass = Class.new(Post)
      post_permission = subject.new(:read, Post)

      expect(post_permission.matches_subject?(Post)).to be true
      expect(post_permission.matches_subject?(subclass)).to be true
      expect(post_permission.matches_subject?(subclass.new)).to be true
    end

    it "matches literal subjects" do
      literal_permission = subject.new(:read, :dashboard)

      expect(literal_permission.matches_subject?(:dashboard)).to be true
      expect(literal_permission.matches_subject?(:settings)).to be false
    end
  end

  describe "#granted?" do
    let(:true_permission) { subject.new(:read, book, predicate: proc { |_u, _s| true }) }
    let(:false_permission) { subject.new(:read, book, predicate: proc { |_u, _s| false }) }

    it "is true for true permission" do
      expect(true_permission.granted?(user, book)).to be true
    end

    it "is false for false permission" do
      expect(false_permission.granted?(user, book)).to be false
    end

    it "passes user and subject to predicate" do
      called_with = nil
      perm = subject.new(:read, book, predicate: proc { |u, s|
        called_with = [u, s]
        true
      })
      perm.granted?(user, book)

      expect(called_with).to eq [user, book]
    end
  end

  describe "#fetch" do
    let(:array_permission) { subject.new(:read, book, query: proc { |_u, _k| [] }) }
    let(:empty_permission) { subject.new(:read, book, query: proc { |_u, _k| }) }

    it "is array for array permission" do
      expect(array_permission.fetch(user, book)).to eq []
    end

    it "is nil for nil permission" do
      expect(empty_permission.fetch(user, book)).to be_nil
    end

    it "passes user and klass to scope" do
      called_with = nil
      perm = subject.new(:read, book, query: proc { |u, k|
        called_with = [u, k]
        []
      })
      perm.fetch(user, book)

      expect(called_with).to eq [user, book]
    end
  end

  describe "#delegated?" do
    it "is true with a delegation" do
      delegation = PapersPlease::Delegation.new(klass: Post, resolver: proc { |_u, a| a })
      perm = subject.new(:read, book, delegation: delegation)

      expect(perm.delegated?).to be true
      expect(perm.granting_class).to eq Post
    end

    it "is false without a delegation" do
      perm = subject.new(:read, book)

      expect(perm.delegated?).to be false
      expect(perm.granting_class).to be_nil
    end
  end
end
