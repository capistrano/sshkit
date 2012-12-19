## Deploy.rb

This is a work in progress alternative backend for what may become Capistrano
*v3.0*.

## Ready?

Nowhere near, it's barely more than a collection of tests, and classes to
prove some concepts; there's nothing you could even use in production even if
you wanted!

## How might it work?

The typical use-case will look something like this:

``` ruby
Deploy::ConnectionManager.backend = :net_ssh
on(%{1.example.com 2.example.com}, in: :parallel) do
  in("/opt/sites/example.com") do
    as("deploy") do
      with({rails_env: :production}) do
        puts capture "ls -lr public/assets/"
        rake "assets:precompile"
      ensure
        runner "S3::Sync.notify"
      end
    end
  end
end
```
One will notice that it's quite low level, but exposes a convenient API, the
`as()`/`in()`/`with()` are nestable in any order, repeatable, and stackable.

Helpers such as `runner()` and `rake()` which expand to `run("rails runner", ...)` and
`run("rake", ...)` are convenience helpers for Rails based apps.

## Parallel

Notice on the `on()` call the `in: :parallel` option, the following will do
what you might expect:

```
on(in: :parallel, limit: 2) { ...}
on(in: :sequence, wait: 5) { ... }
on(in: :parallel, limit: 2, wait: 5) { ... }
```

## Shell Escaping

We've not talked about this extensively, but sufficed to say that we'll test
for, and document the most sane behaviour.

## Output Handling

The output will work very much like MiniTest, in that result and event objects
will be emitted to an IOStream, these classes are emitted at various times,
for example

1. A Command is emitted from each `run()` `rake()` `runner()` etc, this
   command has a handful of instance variables the output formatter can call
   on such as `host` and `command`, the example above might emit something
   like this:

    {
      host: "1.example.com"
      command: "su deploy 'cd /opt/sites/example.com/ && RAILS_ENV=production ls -lr public_assets'"
    }
    {
      host: "1.example.com"
      command: "su deploy 'cd /opt/sites/example.com/ && RAILS_ENV=production rake assets:precompile '"
    }
    {
      host: "1.example.com"
      command: "su deploy 'cd /opt/sites/example.com/ && RAILS_ENV=production rails runner \'S3::Sync.notify\''"
    }

2. When the command results are finished, or in progress (not implemented, streaming responses, such as tail) then
   there is emitted every time a CommandStatus object (might end up being called CommandResult) this will encapsulate
   the logic around success, or error conditions, capturing stderr/out of the result instance.

3. *Responders* might be made available to command objects, which allow you to interact with a command, an example might beL

    run "git checkout", responder: lambda { |prompt| "fullysecret" if prompt =~ /^Password/ }

    The responder needs only to respond to call, and take the prompt (that will be the last line of the standard output of
    the process, if it returns something, that will be written to the processes stdin.
