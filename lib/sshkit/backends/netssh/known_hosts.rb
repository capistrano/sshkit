require "base64"

module SSHKit

  module Backend

    class Netssh < Abstract

      class KnownHostsKeys
        include Mutex_m

        def initialize(path)
          super()
          @path = File.expand_path(path)
          @hosts_keys = nil
        end

        def keys_for(hostlist)
          keys, hashes = hosts_keys, hosts_hashes
          parse_file unless keys && hashes
          keys, hashes = hosts_keys, hosts_hashes

          host_names = hostlist.split(',')

          keys_found = host_names.map { |h| keys[h] || [] }.compact.inject(:&)
          return keys_found unless keys_found.empty?

          host_names.each do |host|
            hashes.each do |(hmac, salt), hash_keys|
              if OpenSSL::HMAC.digest(sha1, salt, host) == hmac
                return hash_keys
              end
            end
          end

          []
        end

        private

        attr_reader :path
        attr_accessor :hosts_keys, :hosts_hashes

        def sha1
          @sha1 ||= OpenSSL::Digest.new('sha1')
        end

        def parse_file
          synchronize do
            return if hosts_keys && hosts_hashes

            unless File.readable?(path)
              self.hosts_keys = {}
              self.hosts_hashes = []
              return
            end

            new_keys = {}
            new_hashes = []
            File.open(path) do |file|
              scanner = StringScanner.new("")
              file.each_line do |line|
                scanner.string = line
                parse_line(scanner, new_keys, new_hashes)
              end
            end
            self.hosts_keys = new_keys
            self.hosts_hashes = new_hashes
          end
        end

        def parse_line(scanner, hosts_keys, hosts_hashes)
          return if empty_line?(scanner)

          hostlist = parse_hostlist(scanner)
          return unless supported_type?(scanner)
          key = parse_key(scanner)

          if hostlist.size == 1 && hostlist.first =~ /\A\|1(\|.+){2}\z/
            hosts_hashes << [parse_host_hash(hostlist.first), key]
          else
            hostlist.each do |host|
              (hosts_keys[host] ||= []) << key
            end
          end
        end

        def parse_host_hash(line)
          _, _, salt, hmac = line.split('|')
          [Base64.decode64(hmac), Base64.decode64(salt)]
        end

        def empty_line?(scanner)
          scanner.skip(/\s*/)
          scanner.match?(/$|#/)
        end

        def parse_hostlist(scanner)
          scanner.skip(/\s*/)
          scanner.scan(/\S+/).split(',')
        end

        def supported_type?(scanner)
          scanner.skip(/\s*/)
          Net::SSH::KnownHosts::SUPPORTED_TYPE.include?(scanner.scan(/\S+/))
        end

        def parse_key(scanner)
          scanner.skip(/\s*/)
          Net::SSH::Buffer.new(scanner.rest.unpack("m*").first).read_key
        end
      end

      class KnownHosts
        include Mutex_m

        def initialize
          super()
          @files = {}
        end

        def search_for(host, options = {})
          keys = ::Net::SSH::KnownHosts.hostfiles(options).map do |path|
            known_hosts_file(path).keys_for(host)
          end.flatten
          ::Net::SSH::HostKeys.new(keys, host, self, options)
        end

        def add(*args)
          ::Net::SSH::KnownHosts.add(*args)
          synchronize { @files = {} }
        end

        private

        def known_hosts_file(path)
          @files[path] || synchronize { @files[path] ||= KnownHostsKeys.new(path) }
        end
      end

    end

  end

end
