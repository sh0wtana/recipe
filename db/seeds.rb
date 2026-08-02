email_address, password =
  if Rails.env.local?
    [ ENV.fetch("SEED_EMAIL", "hoge@example.com"), ENV.fetch("SEED_PASSWORD", "password") ]
  else
    [ ENV["SEED_EMAIL"], ENV["SEED_PASSWORD"] ]
  end

if email_address.present? && password.present?
  User.find_or_create_by!(email_address:) do |user|
    user.password = password
  end
else
  puts "Skipping the user seed: set SEED_EMAIL and SEED_PASSWORD to provision an account."
end
