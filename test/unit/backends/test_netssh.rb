require 'helper'

module SSHKit
  module Backend
    class TestNetssh < UnitTest

      def backend
        @backend ||= Netssh
      end

      def test_net_ssh_configuration_options
        backend.configure do |ssh|
          ssh.pty = true
          ssh.connection_timeout = 30
          ssh.ssh_options = {
            keys: %w(/home/user/.ssh/id_rsa),
            forward_agent: false,
            auth_methods: %w(publickey password)
          }
        end

        assert_equal 30, backend.config.connection_timeout
        assert_equal true, backend.config.pty

        assert_equal %w(/home/user/.ssh/id_rsa),  backend.config.ssh_options[:keys]
        assert_equal false,                       backend.config.ssh_options[:forward_agent]
        assert_equal %w(publickey password),      backend.config.ssh_options[:auth_methods]

      end

      def test_netssh_ext
        assert_includes  Net::SSH::Config.default_files, "#{Dir.pwd}/.ssh/config"
      end

      def test_transfer_summarizer
        netssh = Netssh.new(Host.new('fake'))

        summarizer = netssh.send(:transfer_summarizer,'Transferring')

        [
         [1,    100, :debug, 'Transferring afile 1.0%'],
         [1,    3,   :debug, 'Transferring afile 33.33%'],
         [0,    1,   :debug, 'Transferring afile 0.0%'],
         [1,    2,   :info,  'Transferring afile 50.0%'],
         [0,    0,   :warn,  'percentage 0/0'],
         [1023, 343, :debug, 'Transferring'],
        ].each do |transferred,total,method,substring|
          netssh.expects(method).with { |msg| msg.include?(substring) }
          summarizer.call(nil,'afile',transferred,total)
        end
      end

    end
  end
end
