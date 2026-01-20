module SSHKit

  class Coordinator

    attr_accessor :hosts

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      @hosts = @raw_hosts.any? ? resolve_hosts : []
    end

    def each(**options, &block)
      options = (options[:config] || SSHKit.config).default_runner_config.merge(options)
      
      if hosts  
        case options[:in]
        when :parallel then Runner::Parallel
        when :sequence then Runner::Sequential
        when :groups   then Runner::Group
        else
          options[:in]
        end.new(hosts, **options, &block).execute
      else
        Runner::Null.new(hosts, **options, &block).execute
      end
    end

    private

    def resolve_hosts
      @raw_hosts.collect { |rh| rh.is_a?(Host) ? rh : Host.new(rh) }.uniq
    end

  end

end
