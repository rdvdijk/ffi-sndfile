# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run only the integration specs (they write and read real audio files)"
  RSpec::Core::RakeTask.new(:integration) do |task|
    task.pattern = "spec/integration/**/*_spec.rb"
  end
end

RuboCop::RakeTask.new

task default: %i[spec rubocop]
