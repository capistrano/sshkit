# Usage Examples

## Run a command as a different user

    on hosts do |host|
      as 'www-data' do
        puts capture(:whoami)
      end
    end

## Run with default environmental variables

    SSHKit.config.default_env = { path: '/usr/local/libexec/bin:$PATH' }
    on hosts do |host|
      puts capture(:env)
    end

## Run a command in a different directory

    on hosts do |host|
      within '/var/log' do
        puts capture(:head, '-n5', 'messages')
      end
    end

## Run a command with specific environmental variables

    on hosts do |host|
      with rack_env: :test do
        puts capture("env | grep RACK_ENV")
      end
    end

## Print some arbitrary output with the logging methods

    on hosts do |host|
      f = '/some/file'
      if test("[ -d #{f} ]")
        execute :touch, f
      else
        info "#{f} already exists on #{host}!"
      end
    end

The `debug()`, `info()`, `warn()`, `error()` and `fatal()` honor the current
log level of `SSHKit.config.output_verbosity`

## Run a command in a different directory as a different user

    on hosts do |host|
      as 'www-data' do
        within '/var/log' do
          puts capture(:whoami)
          puts capture(:pwd)
        end
      end
    end

This will output:

    www-data
    /var/log

**Note:** This example is a bit misleading, as the `www-data` user doesn't
have a shell defined, one cannot switch to that user.

## Upload a file from disk

    on hosts do |host|
      upload! '/config/database.yml', '/opt/my_project/shared/database.yml'
    end

**Note:** The `upload!()` method doesn't honor the values of `within()`, `as()`
etc, this will be improved as the library matures, but we're not there yet.

## Upload a file from a stream

    on hosts do |host|
      file = File.open('/config/database.yml')
      io   = StringIO.new(....)
      upload! file, '/opt/my_project/shared/database.yml'
      upload! io,   '/opt/my_project/shared/io.io.io'
    end

The IO streaming is useful for uploading something rather than "cat"ing it,
for example

    on hosts do |host|
      contents = StringIO.new('ALL ALL = (ALL) NOPASSWD: ALL')
      upload! contents, '/etc/sudoers.d/yolo'
    end

This spares one from having to figure out the correct escaping sequences for
something like "echo(:cat, '...?...', '> /etc/sudoers.d/yolo')".

**Note:** The `upload!()` method doesn't honor the values of `within()`, `as()`
etc, this will be improved as the library matures, but we're not there yet.

## Upload a directory of files

    on hosts do |host|
      upload! '.', '/tmp/mypwd', recursive: true
    end

In this case the `recursive: true` option mirrors the same options which are
available to `Net::{SCP,SFTP}`.

## Setting global SSH options

Setting global SSH options, these will be overwritten by options set on the
individual hosts:

    SSHKit::Backend::Netssh.configure do |ssh|
      ssh.connection_timeout = 30
      ssh.ssh_options = {
        keys: %w(/home/user/.ssh/id_rsa),
        forward_agent: false,
        auth_methods: %w(publickey password)
      }
    end

## Run a command with a different effective group ID

    on hosts do |host|
      as user: 'www-data', group: 'project-group' do
        within '/var/log' do
          execute :touch, 'somefile'
          execute :ls, '-l'
        end
      end
    end

One will see that the created file is owned by the user `www-data` and the
group `project-group`.

When combined with the `umask` configuration option, it is easy to share
scripts for deployment between team members without sharing logins.

## Stack directory nestings

    on hosts do
      within "/var" do
        puts capture(:pwd)
        within :log do
          puts capture(:pwd)
        end
      end
    end

This will output:

    /var/
    /var/log

The directory paths are joined using `File.join()`, which should correctly
join parts without forcing the user of the code to care about trailing or
leading slashes. It may be misleading as the `File.join()` is performed on the
machine running the code, if that's a Windows box, the paths may be incorrectly
joined according to the expectations of the machine receiving the commands.

## Running a task in the background

    on hosts do
      within '/opt/sites/example.com' do
        background :rails, :server
      end
    end

This will run something like `nohup /usr/bin/env rails server > /dev/null &`,
backgrounding the Rails process, and making sure we don't leave nohup log
files littering the filesystem.

**Note:** The `background()` method won't do what you expect if you pass a
string `sleep 5`, according to the rules of processing commands, you must call
`background(:sleep, "5")` (that is, command: sleep, args: 5).

**Further Note:** The background() task wraps the given command in `nohup .... &` under some
circumstances the program will hang anyway when the SSH session exits.

## Do not care about the host block

    on hosts do
      # The |host| argument is optional, it will
      # be nil in the block if not passed
    end

## Redirect all output to `/dev/null`

    SSHKit.config.output = File.open('/dev/null')

## Implement a dirt-simple formatter class

    class MyFormatter < SSHKit::Formatter::Abstract
      def write(obj)
        case obj.is_a? SSHKit::Command
          # Do something here, see the SSHKit::Command documentation
        end
      end
    end

    SSHKit.config.output = MyFormatter.new($stdout)
    SSHKit.config.output = MyFormatter.new(SSHKit.config.output)
    SSHKit.config.output = MyFormatter.new(File.open('log/deploy.log', 'wb'))

## Set a password for a host.

    host = SSHKit::Host.new('user@example.com')
    host.password = "hackme"

    on host do |host|
      puts capture(:echo, "I don't care about security!")
    end

## Execute and raise an error if something goes wrong

    on hosts do |host|
      execute!(:echo, '"Example Message!" 1>&2; false')
    end

This will raise `SSHKit::Command:Failed` with the `#message` "Example Message!"
which will cause the command to abort.

## Make a test, or run a command which may fail without raising an error:

    on hosts do |host|
      if test "[ -d /opt/sites ]"
        within "/opt/sites" do
          execute :git, :pull
        end
      else
        execute :git, :clone, 'some-repository', '/opt/sites'
      end
    end

The `test()` command behaves exactly the same as execute however will return
false if the command exits with a non-zero exit (as `man 1 test` does). As it
returns boolean it can be used to direct the control flow within the block.

## Do something different on one host, or another depending on a host property

    host1 = SSHKit::Host.new 'user@example.com'
    host2 = SSHKit::Host.new 'user@example.org'

    on hosts do |host|
      target = "/var/www/sites/"
      if host.hostname =~ /org/
        target += "dotorg"
      else
        target += "dotcom"
      end
      execute! :git, :clone, "git@git.#{host.hostname}", target
    end

## Connect to a host in the easiest possible way

    on 'example.com' do |host|
      execute :uptime
    end

This will resolve the `example.com` hostname into a `SSHKit::Host` object, and
try to pull up the correct configuration for it.


## Run a command without it being command-mapped

If the command you attempt to call contains a space character it won't be
mapped:

    Command.new(:git, :push, :origin, :master).to_s
    # => /usr/bin/env git push origin master
    # (also: execute(:git, :push, :origin, :master)

    Command.new("git push origin master").to_s
    # => git push origin master
    # (also: execute("git push origin master"))

This can be used to access shell builtins (such as `if` and `test`)


## Run a command with a heredoc

An extension of the behaviour above, if you write a command like this:

    c = Command.new <<-EOCOMMAND
      if test -d /var/log
      then echo "Directory Exists"
      fi
    EOCOMMAND
    c.to_s
    # => if test -d /var/log; then echo "Directory Exists; fi
    # (also: execute <<- EOCOMMAND........))

**Note:** The logic which reformats the script into a oneliner may be naïve, but in all
known test cases, it works. The key thing is that `if` is not mapped to
`/usr/bin/env if`, which would break with a syntax error.

## Using with Rake

Into the `Rakefile` simply put something like:

    require 'sshkit/dsl'

    SSHKit.config.command_map[:rake] = "./bin/rake"

    desc "Deploy the site, pulls from Git, migrate the db and precompile assets, then restart Passenger."
    task :deploy do
      on "example.com" do |host|
        within "/opt/sites/example.com" do
          execute :git, :pull
          execute :bundle, :install, '--deployment'
          execute :rake, 'db:migrate'
          execute :rake, 'assets:precompile'
          execute :touch, 'tmp/restart.txt'
        end
      end
    end

## Using without the DSL

The *Coordinator* will resolve all hosts into *Host* objects, you can mix and
match.

    Coordinator.new("one.example.com", SSHKit::Host.new('two.example.com')).each in: :sequence do
      puts capture :uptime
    end

You might also look at `./lib/sshkit/dsl.rb` where you can see almost the
exact code as above, which implements the `on()` method.

## Use the Host properties attribute

Implemented since `v0.0.6`

    servers = %w{one.example.com two.example.com
                 three.example.com four.example.com}.collect do |s|
      h = SSHKit::Host.new(s)
      if s.match /(one|two)/
        h.properties.roles = [:web]
      else
        h.properties.roles = [:app]
      end
    end

    on servers do |host|
      if host.properties.roles.include?(:web)
        # Do something pertinent to web servers
      elsif host.properties.roles.include?(:app)
        # Do something pertinent to application servers
      end
    end

The `SSHKit::Host#properties` is an [`OpenStruct`](http://ruby-doc.org/stdlib-1.9.3/libdoc/ostruct/rdoc/OpenStruct.html)
which is not verified or validated in any way, it is up to you, or your
library to attach meanings or conventions to this mechanism.

## Running local commands

Replace `on` with `run_locally`

    run_locally do
      within '/tmp' do
        execute :whoami
      end
    end

## Using a gateway

SSHKit allow you to use gateway(s). 
All subsequent connections will be tunneled through the gateway(s) (using SSH forwarded ports). To tell SSHKit about your gateways you can either :

* define a global gateway

```ruby
SSHKit.config.backend.configure do |ssh|
    ssh.gateway = "user@my-gateway"
end
```

The gateway definition follows the same syntax as host definition. This means you can define your global gateway like this:

```ruby
SSHKit.config.backend.configure do |ssh|
    ssh.gateway = {
        hostname: "my-gateway",
        user: "user",
        ssh_options: {
        ...
        }
    }
end
```

    
* or define a per host gateway.   

```ruby
host = SSHKit::Host.new(
    :hostname => "private.server", 
    :user => "internal.user", 
    :gateway => "user@my-gateway") 
```

or

```ruby
host = SSHKit::Host.new(
    :hostname => "private.server", 
    :user => "internal.user", 
    :gateway => {
        :hostname => "my-gateway", 
        :user => "user", 
        :ssh_options => {...}
    })
```
