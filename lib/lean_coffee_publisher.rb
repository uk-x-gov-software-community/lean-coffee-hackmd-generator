
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
