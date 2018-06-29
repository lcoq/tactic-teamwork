class Reverter

  attr_reader :file_path,
              :token,
              :domain,
              :time_entries

  def initialize(file_path)
    @file_path = file_path
  end

  def prepare
    @lines = File.readlines(file_path)
    find_data
  end

  def run(callbacks = {})
    time_entries.each do |entry|
      delete_entry entry, callbacks
    end
  end

  private

  attr_reader :lines

  def find_data
    @time_entries = []
    lines.each do |line|
      @token = $1 if line.match(/token\s*:\s*'([^']+)'\Z/i)
      @domain = $1 if line.match(/domain\s*:\s*'([^']+)'\Z/i)
      time_entries << { id: $1 } if line.match(/"timeLogId":"([^"]+)"/)
    end
  end

  def delete_entry(entry, callbacks)
    id = entry[:id]
    url = get_url(id)
    callbacks[:before].call(entry, url) if callbacks[:before]
    response = send_request(url)
    callbacks[:after].call(entry, response) if callbacks[:after]
  rescue => error
    callbacks[:error].call(entry, error) if callbacks[:error]
  end

  def get_url(entry_id)
    "#{domain}/time_entries/#{entry_id}.json"
  end

  def send_request(url)
    options = { basic_auth: { username: token, password: "X" } }
    HTTParty.delete url, options
  end
end
