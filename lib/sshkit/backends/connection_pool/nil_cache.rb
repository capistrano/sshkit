# A cache that holds no connections. Any connection provided to this cache
# is simply closed.
SSHKit::Backend::ConnectionPool::NilCache = Struct.new(:closer) do
  def pop
    nil
  end

  def push(conn)
    closer.call(conn)
  end

  def same_key?(_key)
    true
  end
end
