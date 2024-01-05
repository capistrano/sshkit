require "net/sftp"

module SSHKit
  module Backend
    class Netssh < Abstract
      class SftpTransfer
        def initialize(ssh, summarizer)
          @ssh = ssh
          @summarizer = summarizer
        end

        def upload!(local, remote, options)
          options = { progress: self }.merge(options || {})
          ssh.sftp.connect!
          ssh.sftp.upload!(local, remote, options)
        ensure
          ssh.sftp.close_channel
        end

        def download!(remote, local, options)
          options = { progress: self }.merge(options || {})
          destination = local ? local : StringIO.new.tap { |io| io.set_encoding('BINARY') }

          ssh.sftp.connect!
          ssh.sftp.download!(remote, destination, options)
          local ? true : destination.string
        ensure
          ssh.sftp.close_channel
        end

        def on_get(download, entry, offset, data)
          entry.size ||= download.sftp.file.open(entry.remote) { |file| file.stat.size }
          summarizer.call(nil, entry.remote, offset + data.bytesize, entry.size)
        end

        def on_put(_upload, file, offset, data)
          summarizer.call(nil, file.local, offset + data.bytesize, file.size)
        end

        private

        attr_reader :ssh, :summarizer
      end
    end
  end
end
