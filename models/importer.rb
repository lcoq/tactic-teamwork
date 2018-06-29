require 'date'
require 'csv'
require 'httparty'
require 'json'

class Importer

  attr_reader :file_path,
              :token,
              :domain,
              :lines

  def initialize(file_path:, token:, domain:, **rest)
    @file_path = file_path
    @token = token
    @domain = domain
  end

  def prepare
    @lines = read_and_parse
  end

  def run(callbacks = {})
    lines[:validated].each do |line|
      import_line line, callbacks
    end
  end

  private

  def read_and_parse
    lines = { all: [], skipped: [], errored: [], validated: [] }
    CSV.foreach(file_path, headers: true).with_index(2) do |row, number|
      line = { row: row, number: number, attributes: attributes_from_row(row) }
      lines[:all] << line
      unless line[:attributes]
        lines[:skipped] << line.update(status: :skipped)
        next
      end
      if (errors = attributes_errors(line[:attributes])).any?
        lines[:errored] << line.update(status: :errored, errors: errors)
        next
      end
      lines[:validated] << line.update(status: :validated)
    end
    lines
  end

  def attributes_from_row(row)
    title_with_prefix = row['title'].strip
    match = title_with_prefix.match(/\A\[(\d+)*(\/(\d+))*\]\s*(.*)\Z/)
    return unless match && (match[1] || match[3])
    project_id = match[1]
    task_id = match[3]
    title_without_prefix = match[4]
    date = Date.parse(row['date']).strftime("%Y%m%d") rescue nil
    time = row['start time'] && row['start time'].strip
    duration = row['duration'] && row['duration'].strip
    hours, minutes = duration ? duration.split(':').map(&:to_i).map(&:to_s) : nil
    { 'project_id' => project_id,
      'task_id' => task_id,
      'description' => title_without_prefix,
      'date' => date,
      'time' => time,
      'hours' => hours,
      'minutes' => minutes,
      'isbillable' => '1' }
  end

  def attributes_errors(attributes)
    errors = []
    if !attributes['date']
      errors << "Missing or invalid date"
    end
    if !attributes['time'] || attributes['time'] !~ /\A\d{2}:\d{2}\Z/
      errors << "Missing time"
    end
    if !attributes['hours'] || attributes['hours'] !~ /\A\d+\Z/ || !attributes['minutes'] || attributes['hours'] !~ /\A\d+\Z/
      errors << "Missing or invalid duration"
    end
    errors
  end

  def import_line(line, callbacks)
    attributes = line[:attributes]
    project_id = attributes.delete('project_id')
    task_id = attributes.delete('task_id')
    url = get_url(project_id, task_id)
    callbacks[:before].call(line, url) if callbacks[:before]
    response = send_request(url, attributes)
    callbacks[:after].call(line, response) if callbacks[:after]
  rescue => error
    callbacks[:error].call(line, error) if callbacks[:error]
  end

  def get_url(project_id, task_id)
    if task_id
      "#{domain}/tasks/#{task_id}/time_entries.json"
    else
      "#{domain}/projects/#{project_id}/time_entries.json"
    end
  end

  def send_request(url, attributes)
    options = {
      basic_auth: { username: token, password: "X" },
      body: { 'time-entry' => attributes }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
    HTTParty.post url, options
  end

end
