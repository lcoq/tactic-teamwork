require 'fileutils'

class Logger
  attr_reader :file_name

  def initialize(file_name)
    self.file_name = file_name
  end

  def start
    self.file = create_file
    self
  end

  def stop
    file.close
    self.file = nil
    self
  end

  def log(message, type: :info, prefix: nil)
    full_message = [ "[#{type.to_s.upcase}]", prefix, message ].compact.join(' ')
    file.write "#{full_message}\n"
  end

  def warn(message, prefix: nil)
    log message, type: :warn, prefix: prefix
  end

  def error(message, prefix: nil)
    log message, type: :error, prefix: prefix
  end


  def log_l(line_number, message)
    log message, prefix: "[L#{line_number}]"
  end

  def warn_l(line_number, message)
    log message, type: :warn, prefix: "[L#{line_number}]"
  end

  def error_l(line_number, message)
    log message, type: :error, prefix: "[L#{line_number}]"
  end

  private

  attr_writer :file_name
  attr_accessor :file

  def create_file
    path = File.join(File.dirname(__FILE__), '..', 'logs', file_name)
    FileUtils.mkdir_p File.dirname(File.expand_path(path))
    File.new path, 'w+'
  end
end
