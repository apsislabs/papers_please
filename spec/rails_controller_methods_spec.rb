# frozen_string_literal: true

require "spec_helper"

RSpec.describe PapersPlease::Rails::ControllerMethods do
  around do |example|
    original_policy_class = PapersPlease.instance_variable_get(:@policy_class)
    original_policy_class_name = PapersPlease.instance_variable_get(:@policy_class_name)

    example.run
  ensure
    PapersPlease.instance_variable_set(:@policy_class, original_policy_class)
    PapersPlease.instance_variable_set(:@policy_class_name, original_policy_class_name)
  end

  it "exposes can? and cannot? as helper methods without exposing policy" do
    controller_class = Class.new do
      class << self
        attr_reader :helpers

        def helper_method(*names)
          @helpers = names
        end
      end

      include PapersPlease::Rails::ControllerMethods
    end

    expect(controller_class.helpers).to contain_exactly(:can?, :cannot?)
  end

  it "warns when installing into a controller with method collisions" do
    controller_class = Class.new do
      def can?(*)
      end
    end

    expect do
      PapersPlease::Rails.install_controller_methods(controller_class)
    end.to output(/already defines :can\?/).to_stderr
    expect(controller_class < PapersPlease::Rails::ControllerMethods).to be true
  end

  it "uses the configured policy class" do
    policy_class = Class.new(PapersPlease::Policy) do
      def configure
        role :member

        permit :member do |role|
          role.grant :read, Post, if: proc { true }
        end
      end
    end
    PapersPlease.policy_class = policy_class

    controller = Class.new do
      include PapersPlease::Rails::ControllerMethods

      def current_user
        :user
      end
    end.new

    expect(controller.policy).to be_a(policy_class)
    expect(controller.can?(:read, Post.new)).to be true
    expect(controller.cannot?(:read, :dashboard)).to be true
  end

  it "raises a clear error when no policy class is configured" do
    PapersPlease.policy_class_name = "MissingAccessPolicy"

    controller = Class.new do
      include PapersPlease::Rails::ControllerMethods

      def current_user
        :user
      end
    end.new

    expect { controller.policy }.to raise_error(PapersPlease::Error, /policy_class is not configured/)
  end
end
