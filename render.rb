require 'date'
require 'time'
require 'uri'

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require "lean_coffee"
require "hackmd"
require "lean_coffee_publisher"

h = HackMD.new(auth_token: ENV.fetch("HACKMD_AUTH_TOKEN"))

rolling_idea_generation_url = ENV.fetch("ROLLING_IDEA_GENERATION_URL")
zoom_link = ENV.fetch("ZOOM_LINK")
zoom_passcode = ENV.fetch("ZOOM_PASSCODE")
zoom_meeting_id = ENV.fetch("ZOOM_MEETING_ID")

start_range = ENV.fetch("START_RANGE", "2").to_i
end_range = ENV.fetch("END_RANGE", "4").to_i

next_three = (start_range..end_range).map do |n|
  today = Date.today
  n.times { today = today.next_month }
  today
end

ll = next_three.map do |date|
  params = {
    year: date.year,
    month: date.month,
    zoom_link: zoom_link,
    zoom_passcode: zoom_passcode,
    zoom_meeting_id: zoom_meeting_id,
    rolling_idea_generation_url: rolling_idea_generation_url
  }
  LeanCoffee.new(**params)
end

p = LeanCoffeePublisher.new(hackmd_client: h)
ll.each do |l|
  puts "Publishing: '#{l.event_title}'"
  p.publish(l)
end
