class VagrantWrapper
  class << self
    def hosts
      @vm_hosts ||= begin
        result = {}

        boxes = boxes_list

        unless running?
          boxes.map! do |box|
            box['user'] = ENV['USER']
            box['port'] = '22'
            box
          end
        end

        boxes.each do |vm|
          result[vm['name']] = vm_host(vm)
        end

        result
      end
    end

    def running?
      @running ||= begin
        status = `#{vagrant_binary} status`
        status.include?('running')
      end
    end

    def boxes_list
      json_config_path = File.join('test', 'boxes.json')
      boxes = File.open(json_config_path).read
      JSON.parse(boxes)
    end

    def vagrant_binary
      'vagrant'
    end

    private

    def vm_host(vm)
      host_options = {
          user: vm['user'] || 'vagrant',
          hostname: vm['hostname'] || 'localhost',
          port: vm['port'] || '22',
          password: vm['password'] || 'vagrant'
      }

      SSHKit::Host.new(host_options)
    end
  end
end
