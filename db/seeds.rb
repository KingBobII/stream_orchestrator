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
# db/seeds.rb
# db/seeds.rb

puts "🧹 Cleaning database..."

Stream.destroy_all
YoutubeChannel.destroy_all
User.destroy_all

puts "👤 Creating users..."

admin = User.create!(
  email: "admin@example.com",
  name: "Admin User",
  role: "admin",
  password: "password123",
  password_confirmation: "password123"
)

stream_operator = User.create!(
  email: "stream@example.com",
  name: "Stream Operator",
  role: "stream_operator",
  password: "password123",
  password_confirmation: "password123"
)

production_operator = User.create!(
  email: "production@example.com",
  name: "Production Operator",
  role: "production_operator",
  password: "password123",
  password_confirmation: "password123"
)

puts "✅ Users created!"

# ----------------------------------------
# 📺 YOUTUBE CHANNELS
# ----------------------------------------

puts "📺 Creating YouTube channels..."

channels = [
  {
    name: "Government Live",
    external_id: "UC-GOV-001",
    description: "Official government livestreams",
    owner: admin
  },
  {
    name: "City Council Streams",
    external_id: "UC-CITY-002",
    description: "City council meetings and updates",
    owner: stream_operator
  },
  {
    name: "Public Announcements",
    external_id: "UC-PUBLIC-003",
    description: "Public service announcements",
    owner: admin
  }
]

channels.each do |attrs|
  channel = YoutubeChannel.create!(
    name: attrs[:name],
    external_id: attrs[:external_id],
    description: attrs[:description],
    status: "active",
    owner: attrs[:owner],
    published_at: 1.year.ago
  )

  puts "Created channel: #{channel.name}"
end

puts "✅ Channels created!"

# ----------------------------------------
# 🎥 STREAMS
# ----------------------------------------

puts "🎥 Creating streams..."

channels = YoutubeChannel.all

streams_data = [
  {
    title: "Budget Speech 2026",
    description: "Annual national budget speech",
    status: "scheduled",
    visibility: "public",
    scheduled_at: 2.days.from_now,
    youtube_channel: channels[0]
  },
  {
    title: "Emergency Press Briefing",
    description: "Urgent national update",
    status: "live",
    visibility: "public",
    scheduled_at: Time.current,
    youtube_channel: channels[0]
  },
  {
    title: "City Council Meeting - March",
    description: "Monthly council meeting",
    status: "scheduled",
    visibility: "unlisted",
    scheduled_at: 1.day.from_now,
    youtube_channel: channels[1]
  },
  {
    title: "Infrastructure Update",
    description: "Road and transport updates",
    status: "ended",
    visibility: "public",
    scheduled_at: 2.days.ago,
    youtube_channel: channels[1]
  },
  {
    title: "Health Department Briefing",
    description: "Public health updates",
    status: "scheduled",
    visibility: "private",
    scheduled_at: 3.days.from_now,
    youtube_channel: channels[2]
  },
  {
    title: "Education Reform Announcement",
    description: "New policies for education",
    status: "ended",
    visibility: "public",
    scheduled_at: 5.days.ago,
    youtube_channel: channels[2]
  }
]

streams_data.each do |attrs|
  stream = Stream.create!(
    title: attrs[:title],
    description: attrs[:description],
    status: attrs[:status],
    visibility: attrs[:visibility],
    scheduled_at: attrs[:scheduled_at],
    youtube_channel: attrs[:youtube_channel],
    thumbnails: {
      "high" => {
        "url" => "https://via.placeholder.com/480x360.png?text=Stream"
      }
    }
  )

  puts "Created stream: #{stream.title} (#{stream.status})"
end

puts "✅ Streams created!"

puts "🎉 Seeding complete!"
