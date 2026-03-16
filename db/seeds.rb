# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Destroy old users to avoid duplicates (optional, careful in production!)
User.destroy_all

puts "Creating default users..."

users = [
  { email: "admin@example.com", name: "Admin User", role: "admin", password: "password123" },
  { email: "stream@example.com", name: "Stream Operator", role: "stream_operator", password: "password123" },
  { email: "production@example.com", name: "Production Operator", role: "production_operator", password: "password123" }
]

users.each do |user_attrs|
  User.create!(
    email: user_attrs[:email],
    name: user_attrs[:name],
    role: user_attrs[:role],
    password: user_attrs[:password],
    password_confirmation: user_attrs[:password]
  )
  puts "Created user: #{user_attrs[:email]} (#{user_attrs[:role]})"
end

puts "✅ All default users created!"
