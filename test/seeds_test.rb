require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeding creates an account that can sign in" do
    with_seed_env(email: "seed@example.com", password: "secret password") do
      Rails.application.load_seed
    end

    assert User.authenticate_by(email_address: "seed@example.com", password: "secret password")
  end

  test "re-seeding leaves an existing account's password alone" do
    with_seed_env(email: "seed@example.com", password: "first password") do
      Rails.application.load_seed
    end
    digest = User.find_by!(email_address: "seed@example.com").password_digest

    with_seed_env(email: "seed@example.com", password: "second password") do
      Rails.application.load_seed
    end

    assert_equal digest, User.find_by!(email_address: "seed@example.com").password_digest
  end

  # Defaulting outside development would provision a known address and password
  # onto a public host — a backdoor, not a convenience. It must not raise either:
  # bin/docker-entrypoint runs db:prepare on boot, which seeds a freshly created
  # database, so a raise here is a boot loop on the first deploy.
  test "seeding outside development without credentials creates nothing and does not raise" do
    with_seed_env(email: nil, password: nil) do
      as_rails_env("production") do
        assert_no_difference -> { User.count } do
          Rails.application.load_seed
        end
      end
    end
  end

  private
    def as_rails_env(environment)
      original = Rails.env.to_s
      Rails.env = environment
      yield
    ensure
      Rails.env = original
    end

    def with_seed_env(email:, password:)
      original = ENV.values_at("SEED_EMAIL", "SEED_PASSWORD")
      ENV["SEED_EMAIL"], ENV["SEED_PASSWORD"] = email, password
      yield
    ensure
      ENV["SEED_EMAIL"], ENV["SEED_PASSWORD"] = original
    end
end
