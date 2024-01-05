require 'helper'
require 'tempfile'

module SSHKit
  module Backend
    class TestNetssh < UnitTest

      def teardown
        super
        # Reset config to defaults after each test
        backend.instance_variable_set :@config, nil
      end

      def backend
        @backend ||= Netssh
      end

      def test_net_ssh_configuration_options
        backend.configure do |ssh|
          ssh.pty = true
          ssh.connection_timeout = 30
          ssh.transfer_method = :sftp
          ssh.ssh_options = {
            keys: %w(/home/user/.ssh/id_rsa),
            forward_agent: false,
            auth_methods: %w(publickey password)
          }
        end

        assert_equal 30, backend.config.connection_timeout
        assert_equal :sftp, backend.config.transfer_method
        assert_equal true, backend.config.pty

        assert_equal %w(/home/user/.ssh/id_rsa),  backend.config.ssh_options[:keys]
        assert_equal false,                       backend.config.ssh_options[:forward_agent]
        assert_equal %w(publickey password),      backend.config.ssh_options[:auth_methods]
        assert_instance_of backend::KnownHosts,   backend.config.ssh_options[:known_hosts]
      end

      def test_transfer_method_prohibits_invalid_values
        error = assert_raises ArgumentError do
          backend.configure do |ssh|
            ssh.transfer_method = :nope
          end
        end

        assert_match ":nope is not a valid transfer method", error.message
      end

      def test_transfer_method_does_not_allow_nil
        error = assert_raises ArgumentError do
          backend.configure do |ssh|
            ssh.transfer_method = nil
          end
        end

        assert_match "nil is not a valid transfer method", error.message
      end

      def test_transfer_method_defaults_to_scp
        assert_equal :scp, backend.config.transfer_method
      end

      def test_host_can_override_transfer_method
        backend.configure do |ssh|
          ssh.transfer_method = :scp
        end

        host = Host.new("fake")
        host.transfer_method = :sftp

        netssh = backend.new(host)
        netssh.stubs(:with_ssh).yields(nil)

        netssh.send(:with_transfer, nil) do |transfer|
          assert_instance_of Netssh::SftpTransfer, transfer
        end
      end

      def test_netssh_ext
        assert_includes  Net::SSH::Config.default_files, "#{Dir.pwd}/.ssh/config"
      end

      def test_transfer_summarizer
        netssh = Netssh.new(Host.new('fake'))

        summarizer = netssh.send(:transfer_summarizer,'Transferring')

        [
         [1,    1000, :debug, 'Transferring afile 0.1%'],
         [1,    100,  :debug, 'Transferring afile 1.0%'],
         [99,   1000, :debug, 'Transferring afile 9.9%'],
         [15,   100,  :info,  'Transferring afile 15.0%'],
         [1,    3,    :info,  'Transferring afile 33.33%'],
         [0,    1,    :debug, 'Transferring afile 0.0%'],
         [1,    2,    :info,  'Transferring afile 50.0%'],
         [0,    0,    :warn,  'percentage 0/0'],
         [1023, 343,  :info,  'Transferring'],
        ].each do |transferred,total,method,substring|
          netssh.expects(method).with { |msg| msg.include?(substring) }
          summarizer.call(nil,'afile',transferred,total)
        end
      end

      def test_transfer_summarizer_uses_verbosity
        netssh = Netssh.new(Host.new('fake'))
        summarizer = netssh.send(:transfer_summarizer, 'Transferring', verbosity: :ERROR)
        netssh.expects(:error).with { |msg| msg.include?('Transferring afile 15.0%') }
        summarizer.call(nil,'afile',15,100)
      end

      if Net::SSH::Version::CURRENT >= Net::SSH::Version[3, 1, 0]
        def test_known_hosts_for_when_all_hosts_are_recognized
          perform_known_hosts_test('github', 'github.com')
        end

        def test_known_hosts_for_when_an_host_hash_is_recognized
          perform_known_hosts_test('github_hash', 'github.com')
        end

        def test_known_hosts_for_with_multiple_hosts
          perform_known_hosts_test('github', '192.30.252.123,github.com', 0)
          perform_known_hosts_test('github_ip', '192.30.252.123,github.com', 1)
        end
      end

      private

      def perform_known_hosts_test(hostfile, hostlist, keys_count = 1)
        source = File.join(File.dirname(__FILE__), '../../known_hosts', hostfile)
        kh = Netssh::KnownHosts.new
        keys = kh.search_for(hostlist, user_known_hosts_file: source, global_known_hosts_file: Tempfile.new('sshkit-test').path)

        assert_instance_of ::Net::SSH::HostKeys, keys
        assert_equal(keys_count, keys.count)
        keys.each do |key|
          assert_equal("ssh-rsa", key.ssh_type)
        end
      end
    end
  end
end
