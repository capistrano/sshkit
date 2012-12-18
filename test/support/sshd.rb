require 'erb'
require 'socket'
require 'fileutils'
require 'daemon_controller'

class SSH
  class << self

    def daemon
      DaemonController.new(
        :identifier     => "Test SSH Server",
        :start_command  => "#{sshd} -f #{configuration_file} -h #{hostkey_file} -e 2> #{log_file}",
        :ping_command   => lambda { TCPSocket.new('localhost', 2234) },
        :pid_file       => pid_file,
        :log_file       => log_file,
        :before_start   => lambda { create_sandbox! }
      )
    end

    def write_configurations
      write_configuration_file! unless File.exists?(configuration_file)
      write_hostkey_file!       unless File.exists?(hostkey_file)
    end

    def write_configurations!
      File.unlink configuration_file if File.exists?(configuration_file)
      File.unlink hostkey_file       if File.exists?(hostkey_file)
      write_configurations
    end

    def create_sandbox!
      chroot
    end

    private
      def sshd
        `which sshd`.chomp
      end
      def write_configuration_file!
        File.open(configuration_file, "w") do |file|
          file.write ERB.new(default_configuration).result(binding).gsub(/^\s+/, '')
        end
      end
      def log_file
        log = File.join(Dir.pwd, %w(test tmp sshd log sshd-error.log))
        FileUtils.mkdir_p(File.dirname(log))
        log
      end
      def hostkey_file
        host = File.join(Dir.pwd, %w(test tmp sshd config sshd_hostkey))
        FileUtils.mkdir_p(File.dirname(host))
        host
      end
      def write_hostkey_file!
        `echo 'Y' | ssh-keygen -b 1024 -f #{hostkey_file} -N ''`
      end
      def configuration_file
        conf = File.join(Dir.pwd, %w(test tmp sshd config default.conf))
        FileUtils.mkdir_p(File.dirname(conf))
        conf
      end
      def default_configuration
        <<-EOB
          Port 2234
          ListenAddress 127.0.0.1
          Protocol 2
          StrictModes yes
          PasswordAuthentication yes
          ChrootDirectory <%= chroot %>
          PidFile <%= pid_file %>
          LogLevel DEBUG
        EOB
      end
      def chroot
        chroot = File.join(Dir.pwd, %w(test tmp sshd sandbox))
        FileUtils.mkdir_p(chroot)
        chroot
      end
      def pid_file
        pid = File.join(Dir.pwd, %w(test tmp sshd pids sshd.pid))
        FileUtils.mkdir_p(File.dirname(pid))
        pid
      end
  end
end
