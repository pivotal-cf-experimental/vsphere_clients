module WaitHelpers
  def wait(retries_left, interval, &blk)
    blk.call
  rescue
    retries_left -= 1
    if retries_left > 0
      sleep(interval)
      retry
    else
      raise
    end
  end
end

RSpec.configure do |config|
  config.include(WaitHelpers)
end
