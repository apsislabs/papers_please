# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :standard do
  sh "bundle exec standardrb"
end

task default: [:standard, :spec]
