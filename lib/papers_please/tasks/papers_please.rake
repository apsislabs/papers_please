# frozen_string_literal: true

namespace :papers_please do
  desc "Print out all defined roles and permissions in match order"
  task :roles, [:klass] => :environment do |_, args|
    policy_klass = args[:klass] ? Object.const_get(args[:klass]) : PapersPlease.policy_class

    puts "Generating Role/Permission Table for #{policy_klass}...\n\n"
    PapersPlease.permissions_table(policy_klass)
  end
end
