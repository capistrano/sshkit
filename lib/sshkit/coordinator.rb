module SSHKit

  class Coordinator

    attr_accessor :hosts

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      raise NoValidHosts unless Array(raw_hosts).any?
      resolve_hosts!
    end

    def each(options={}, &block)
      options = default_options.merge(options)
      case options[:in]
      when :parallel then Runner::Parallel
      when :sequence then Runner::Sequential
      when :groups   then Runner::Group
      else
        raise RuntimeError, "Don't know how to handle run style #{options[:in].inspect}"
      end.new(hosts, &block).execute
    end

    private

      attr_accessor :cooldown

      def default_options
        { in: :parallel }
      end

      def resolve_hosts!
        @hosts = @raw_hosts.collect { |rh| rh.is_a?(Host) ? rh : Host.new(rh) }.uniq
      end

  end

end
