require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Add this line near the top
require "active_support/testing/time_helpers"

RSpec.configure do |config|
  # Add this block to include time helpers
  config.include ActiveSupport::Testing::TimeHelpers

  # Existing config...
  config.fixture_paths = [
    Rails.root.join("spec/fixtures")
  ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
