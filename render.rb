require 'date'
require 'time'
require 'uri'
require 'erb'
require 'httparty'
require 'json'
require 'tzinfo'

class HackMD
  include HTTParty
  base_uri 'https://api.hackmd.io/v1'

  attr_reader :auth_token

  READ_PERMISSIONS = %I{owner signed_in guest}
  WRITE_PERMISSIONS = %I{owner signed_in guest}
  COMMENT_PERMISSIONS =	%I{disabled forbidden owners signed_in_users everyone}

  def initialize(auth_token: )
    @auth_token = auth_token
  end

  def headers
    {
      "Authorization" => "Bearer #{auth_token}"
    }
  end

  def me
    self.class.get("/me", headers: headers)
  end

  def notes
    self.class.get("/notes", headers: headers)
  end

  def find_note_by_title(title)
    notes.find {|n| n['title'] == title}
  end

  def create_note(title:, content:, read_permission:, write_permission:, comment_permission: )
    body = {
      title: title,
      content: content,
      readPermission: read_permission,
      writePermission: write_permission,
      commentPermission: comment_permission
    }
    self.class.post("/notes", body: body.to_json, headers: headers.merge("Content-type" => "application/json"))
  end

  def update_note(note_id:, content:, read_permission:, write_permission:)
    body = {
      content: content,
      readPermission: read_permission,
      writePermission: write_permission
    }
    self.class.patch("/notes/#{note_id}", body: body.to_json, headers: headers.merge("Content-type" => "application/json"))
  end
end

class LeanCoffeePublisher
  attr_reader :hackmd, :created

  def initialize(hackmd_client:)
    @hackmd = hackmd_client
    @created = nil
  end

  def truncate(id)
    id[0...4] + "****"
  end

  def publish(lean_coffee)
    note = hackmd.find_note_by_title(lean_coffee.event_title)

    if note
      puts "Found existing note #{truncate(note['id'])}"
      @created = note
    else
      puts "Creating note #{lean_coffee.event_title}"
      @created = hackmd.create_note(
        title: lean_coffee.event_title,
        content: lean_coffee.render,
        read_permission: :guest,
        write_permission: :guest,
        comment_permission: :everyone
      )
      puts "Created note #{truncate(@created['id'])}"
    end

    lean_coffee.hackmd_url = created["publishLink"]

    puts "updating note #{truncate(created['id'])}"

    hackmd.update_note(
      note_id: @created["id"],
      content: lean_coffee.render,
      read_permission: :guest,
      write_permission: :guest
    )
  end
end

class LeanCoffee
  attr_reader :meeting_id, :passcode, :zoom_link, :event_host, :date, :rolling_idea_generation_url
  attr_accessor :hackmd_url

  def initialize(year:, month:, zoom_meeting_id:, zoom_passcode:, zoom_link:, rolling_idea_generation_url:)
    @meeting_id = zoom_meeting_id
    @passcode = zoom_passcode
    @zoom_link = zoom_link
    @rolling_idea_generation_url = rolling_idea_generation_url
    @hackmd_url = "TBD"
    @event_host = "TBD"
    @date = fourth_thursday(year, month)
  end

  def self.create_next_month
    d = Date.today.next_month
    LeanCoffee.new(year: d.year, month: d.month)
  end

  def fourth_thursday(year, month)
    start_of_month = Date.new(year,month,1)
    start_of_next_month = start_of_month.next_month
    thursdays = (start_of_month...start_of_next_month).select(&:thursday?)
    thursdays[3]
  end

  def description
    <<~END_DESC
      Meeting of the Cross Government Community, featuring talks and Lean Coffee discussion.

      Agenda:

      #{hackmd_url}

      Join on zoom #{zoom_link}
      Meeting ID: #{meeting_id}
      Passcode: #{passcode}
    END_DESC
  end

  def calendar_url
    URI::HTTPS.build(
      host: 'ics.agical.io',
      path: '/',
      query: URI.encode_www_form({
        subject: "Cross Government Software Community Lean Coffee",
        description: description,
        location: zoom_link,
        dtstart: start_time.iso8601,
        dtend: end_time.iso8601,
        reminder: "10"
      })).to_s
  end

  def start_time
    tz = TZInfo::Timezone.get('Europe/London')
    tz.local_datetime(date.year, date.month, date.day, 11, 0, 0)
  end

  def end_time
    start_time + (1/24r)
  end

  def event_title
    "Xgov software lean coffee - " + event_date_time
  end

  def event_date_time
    start_time.strftime("%a %d %b %Y %H:%M - ") + end_time.strftime("%H:%M")
  end

  def render
    template = ERB.new(File.read(File.dirname(__FILE__) + "/hackmd.erb"))
    template.result(binding)
  end

  def render_to_file
    File.write(start_time.strftime("%d-%b-%Y-lean-coffee.md"), render)
  end

end

h = HackMD.new(auth_token: ENV.fetch("HACKMD_AUTH_TOKEN"))

rolling_idea_generation_url = ENV.fetch("ROLLING_IDEA_GENERATION_URL")
zoom_link = ENV.fetch("ZOOM_LINK")
zoom_passcode = ENV.fetch("ZOOM_PASSCODE")
zoom_meeting_id = ENV.fetch("ZOOM_MEETING_ID")


next_three = (2..4).map do |n|
  today = Date.today
  n.times { today = today.next_month }
  today
end


ll = next_three.map do |date|
  LeanCoffee.new(year: date.year, month: date.month, zoom_link: zoom_link, zoom_passcode: zoom_passcode, zoom_meeting_id: zoom_meeting_id, rolling_idea_generation_url: rolling_idea_generation_url)
end

p = LeanCoffeePublisher.new(hackmd_client: h)
ll.each do |l|
  puts "Publishing: '#{l.event_title}'"
  p.publish(l)
end
