require 'set'

module SSHKit
  class DeprecationLogger
    def initialize(out)
      @out = out
      @previous_warnings = Set.new
    end

    def log(message)
      return if @out.nil?
      warning_msg = "[Deprecated] #{message}\n"
      caller_line = caller.find { |line| !line.include?('lib/sshkit') }
      warning_msg << "    (Called from #{caller_line})\n" unless caller_line.nil?
      @out << warning_msg unless @previous_warnings.include?(warning_msg)
      @previous_warnings << warning_msg
    end
  end
end
