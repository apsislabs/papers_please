# frozen_string_literal: true

require 'papers_please/version'
require 'papers_please/errors'
require 'papers_please/policy'
require 'papers_please/role'
require 'papers_please/permission'
require 'papers_please/rails/controller_methods'
require 'papers_please/railtie' if defined? Rails

module PapersPlease
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
  def self.permissions_table(policy_klass)
    require 'terminal-table'

    policy = policy_klass.new(:system)

    table = ::Terminal::Table.new do |t|
      t.headings = [
        'role',
        'subject',
        'permission',
        'has query?',
        'has predicate?',
        'granted by other?'
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
              permission.query ? 'yes' : 'no',
              permission.predicate ? 'yes' : 'no',
              permission.granted_by_other? ? 'yes' : 'no'
            ]

            first_line_of_role = false
          end
        end
      end
    end

    puts table.to_s

    table.to_s
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength
end
