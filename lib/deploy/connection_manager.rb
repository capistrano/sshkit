require 'timeout'

class Runner

  attr_reader :hosts, :block

  def initialize(hosts, &block)
    @hosts       = Array(hosts)
    @block       = block
  end

end

class ParallelRunner < Runner
  def execute
    threads = []
    hosts.each do |host|
      threads << Thread.new(host) do |h|
        Deploy.config.backend.new(host, &block).run
      end
    end
    threads.map(&:join)
  end
end

class SequentialRunner < Runner
  attr_writer :wait_interval
  def execute
    hosts.each do |host|
      Deploy.config.backend.new(host, &block).run
      sleep wait_interval
    end
  end
  private
  def wait_interval
    @wait_interval ||= 2
  end
end

class GroupRunner < SequentialRunner
  attr_writer :group_size
  def execute
    hosts.each_slice(group_size).collect do |group_hosts|
      ParallelRunner.new(group_hosts, &block).execute
      sleep wait_interval
    end.flatten
  end
  private
  def group_size
    @group_size ||= 2
  end
end

module Deploy

  NoValidHosts = Class.new(StandardError)

  class ConnectionManager

    attr_accessor :hosts

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      raise NoValidHosts unless Array(raw_hosts).any?
      resolve_hosts!
    end

    def each(options={}, &block)
      options = default_options.merge(options)
      case options[:in]
      when :parallel then ParallelRunner
      when :sequence then SequentialRunner
      when :groups   then GroupRunner
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
