# frozen_string_literal: true

namespace :papers_please do
  desc 'Print out all defined roles and permissions in match order'
  task :roles, [:klass] => :environment do |_, _args|
    klass = klass ? Object.const_get(klass) : AccessPolicy

    puts "Generating Role/Permission Table for #{klass}...\n\n"
    PapersPlease.permissions_table(klass)
  end
end
