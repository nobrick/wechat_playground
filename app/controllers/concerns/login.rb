module Login
  extend ActiveSupport::Concern

  def login_required
    redirect_to new_session_url unless login?
  end

  def no_login_required
    redirect_to session_url if login?
  end

  def login?
    !!session[:uin]
  end

  def login_as(uin, secret)
    return false if uin.nil? || secret.nil?
    key = redis_key_uin_secret(uin)
    if redis.get(key) == secret
      session[:uin] = uin
      redis.del(key)
      true
    else
      false
    end
  end

  def logout
    session[:uin] = nil
  end

  def set_uin_secret_for(uin, expiry = 180)
    SecureRandom.uuid().tap do |secret|
      redis.setex(redis_key_uin_secret(uin), expiry, secret)
    end
  end

  private

  def redis_key_uin_secret(uin)
    "wechat_playground/uin_secret/#{uin}"
  end

  def redis
    @redis ||= Redis.new
  end
end
