# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov.start { add_filter "/spec/" }
end

require "sndfile"

require_relative "lib/tmp_files"
require_relative "lib/audio_helpers"
require_relative "lib/ogg_vorbis_reader"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed

  config.include TmpFiles
  config.include AudioHelpers
  config.after { remove_tmp_dir }

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
