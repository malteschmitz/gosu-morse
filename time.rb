def nanos
  Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
end

p nanos

loop do
  start = nanos
  10.times do
    sleep(0.05)
  end
  p (nanos - start) / 1000000.0
end