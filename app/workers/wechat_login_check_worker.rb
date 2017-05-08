require 'wechat_client'

class WechatLoginCheckWorker
  include Sidekiq::Worker
  include MessageBusHelper
  sidekiq_options retry: 0, dead: false
  attr_reader :message_bus_token

  def perform(message_bus_token, uuid, times = 20)
    set_message_bus_token(message_bus_token)
    if times <= 0
      publish('request_too_much')
      return
    end
    check_login(uuid, times)
  end

  private

  def check_login(uuid, times)
    code = client.check_login(uuid)
    case code
    when '200'
      publish('login_success')
      payload = {
        message_bus_token: message_bus_token,
        login_info: client.login_info,
        cookies: client.cookies
      }
      logger.info(payload)
      WechatWebInitWorker.perform_async(payload)
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

  def recheck(uuid, times)
    WechatLoginCheckWorker.perform_async(message_bus_token, uuid, times)
  end

  def client
    @client ||= WechatClient::Core.new()
  end

  def set_message_bus_token(message_bus_token)
    @message_bus_token = message_bus_token
  end
end
