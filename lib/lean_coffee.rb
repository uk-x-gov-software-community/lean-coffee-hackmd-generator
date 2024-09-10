require 'erb'
require 'tzinfo'

class LeanCoffee
  attr_reader :meeting_id, :passcode, :zoom_link, :event_host, :date, :rolling_idea_generation_url
  attr_accessor :hackmd_url

  def initialize(
    year:, month:,
    start_hour: 11,
    start_minute: 00,
    duration_in_hours: 1,
    zoom_meeting_id:,
    zoom_passcode:,
    zoom_link:,
    rolling_idea_generation_url:,
    event_title_override: nil,
    meeting_description_override: nil)

    @meeting_id = zoom_meeting_id
    @passcode = zoom_passcode
    @zoom_link = zoom_link
    @rolling_idea_generation_url = rolling_idea_generation_url
    @hackmd_url = "TBD"
    @event_host = "TBD"
    @date = fourth_thursday(year, month)
    @start_hour = start_hour
    @start_minute = start_minute
    @duration_in_hours = duration_in_hours
    @event_title_override = event_title_override
    @meeting_description_override = meeting_description_override
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

  def calendar_description
    <<~END_DESC
      #{meeting_description}

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
        subject: calendar_title,
        description: calendar_description,
        location: zoom_link,
        dtstart: start_time.iso8601,
        dtend: end_time.iso8601,
        reminder: "10"
      })).to_s
  end

  def meeting_description
    @meeting_description_override || "Meeting of the Cross Government Community, featuring talks and Lean Coffee discussion."
  end

  def start_time
    tz = TZInfo::Timezone.get('Europe/London')
    tz.local_datetime(date.year, date.month, date.day, @start_hour, @start_minute, 0)
  end

  def end_time
    start_time + (@duration_in_hours/24r)
  end

  def calendar_title
    @event_title_override || "Cross Government Software Community Lean Coffee"
  end

  def event_title
    @event_title_override || ("Xgov software lean coffee - " + event_date_time)
  end

  def event_date_time
    start_time.strftime("%a %d %b %Y %H:%M - ") + end_time.strftime("%H:%M")
  end

  def template_filename
    File.dirname(__FILE__) + "/template.erb"
  end

  def render
    template = ERB.new(File.read(template_filename))
    template.result(binding)
  end

  def render_to_file
    File.write(start_time.strftime("%d-%b-%Y-lean-coffee.md"), render)
  end

end
