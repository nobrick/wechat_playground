module ContactProcessedCounter
  extend ActiveSupport::Concern

  def incr_processed_count(uin)
    redis.incr(counter_key(uin))
  end

  def reset_processed_count(uin)
    redis.set(counter_key(uin), 0)
  end

  private

  def counter_key(uin)
    "wechat_playground/contact_processed_count/#{uin}"
  end

  def redis
    @redis ||= Redis.new
  end
end
