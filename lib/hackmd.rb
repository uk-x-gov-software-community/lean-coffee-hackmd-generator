require 'httparty'
require 'json'

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
