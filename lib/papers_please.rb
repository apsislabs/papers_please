# frozen_string_literal: true

require "papers_please/version"
require "papers_please/errors"
require "papers_please/delegation"
require "papers_please/policy"
require "papers_please/role"
require "papers_please/permission"
require "papers_please/rails/controller_methods"
require "papers_please/railtie" if defined? Rails

module PapersPlease
  class << self
    attr_writer :policy_class

    def policy_class
      @policy_class ||= Object.const_get(policy_class_name)
    rescue NameError
      raise Error, "PapersPlease.policy_class is not configured and #{policy_class_name} is not defined"
    end

    def policy_class_name
      @policy_class_name ||= "AccessPolicy"
    end

    def policy_class_name=(value)
      @policy_class = nil
      @policy_class_name = value
    end
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
  def self.permissions_table(policy_klass)
    require "terminal-table"

    policy = policy_klass.new(:system)

    table = ::Terminal::Table.new do |t|
      t.headings = [
        "role",
        "subject",
        "permission",
        "has query?",
        "has predicate?",
        "granted by other?"
      ]

      policy.roles.each_with_index do |(name, role), index|
        t.add_separator unless index.zero?
        first_line_of_role = true

        role.permissions.group_by(&:subject).each do |subject, permissions|
          permissions.each do |permission|
            t.add_row [
              first_line_of_role ? name : nil,
              subject,
              permission.key,
              permission.query ? "yes" : "no",
              permission.predicate ? "yes" : "no",
              permission.granted_by_other? ? "yes" : "no"
            ]

            first_line_of_role = false
          end
        end
      end
    end

    puts table

    table.to_s
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength
end
