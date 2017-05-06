require 'wechat_client'

class WechatLoginCheckWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0, dead: false

  def perform(uuid, times = 20)
    if times <= 0
      publish('request_too_much')
      return
    end

    check_login(uuid, times)
  end

  private

  def check_login(uuid, times)
    client = WechatClient::Core.new()
    code = client.check_login(uuid)
    case code
    when '200'
      publish('login_success')
    when '201'
      publish('wait_for_confirm')
      recheck(uuid, times - 1)
    when '408'
      publish('login_error', code: code)
      recheck(uuid, times - 1)
    else
      publish('login_error', code: code)
    end
  end

  def publish(status, params = {})
    MessageBus.publish("/channel", {status: status}.merge(params).to_json)
  end

  def recheck(uuid, times)
    WechatLoginCheckWorker.perform_async(uuid, times)
  end
end
