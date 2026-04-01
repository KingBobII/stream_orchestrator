puts "🧹 Cleaning database..."

Stream.destroy_all
YoutubeChannel.destroy_all
User.destroy_all

puts "👤 Creating users..."

shared_stream_access_key = "shared-gov-stream-access"

admin = User.create!(
  email: "admin@example.com",
  name: "Admin User",
  role: "admin",
  stream_access_key: shared_stream_access_key,
  password: "password123",
  password_confirmation: "password123"
)

stream_operator = User.create!(
  email: "stream@example.com",
  name: "Stream Operator",
  role: "stream_operator",
  stream_access_key: shared_stream_access_key,
  password: "password123",
  password_confirmation: "password123"
)

production_operator = User.create!(
  email: "production@example.com",
  name: "Production Operator",
  role: "production_operator",
  stream_access_key: SecureRandom.hex(12),
  password: "password123",
  password_confirmation: "password123"
)

puts "✅ Users created!"

# ----------------------------------------
# 📺 YOUTUBE CHANNELS
# ----------------------------------------

puts "📺 Creating YouTube channels..."

channels_data = [
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
    owner: admin
  },
  {
    name: "Public Announcements",
    external_id: "UC-PUBLIC-003",
    description: "Public service announcements",
    owner: admin
  }
]

channels_data.each do |attrs|
  channel = YoutubeChannel.create!(
    name: attrs[:name],
    external_id: attrs[:external_id],
    description: attrs[:description],
    status: "active",
    owner: attrs[:owner],
    stream_access_key: attrs[:owner].stream_access_key,
    published_at: 1.year.ago
  )

  puts "Created channel: #{channel.name}"
end

puts "✅ Channels created!"

# ----------------------------------------
# 🎥 STREAMS
# ----------------------------------------

puts "🎥 Creating streams..."

channels = YoutubeChannel.order(:id).to_a

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
