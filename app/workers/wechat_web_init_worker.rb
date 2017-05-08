require 'wechat_client'

class WechatWebInitWorker
  include Sidekiq::Worker
  include MessageBusHelper
  include Login
  sidekiq_options retry: 0, dead: false
  attr_reader :message_bus_token, :params

  def perform(payload)
    set_payload(payload)
    client.web_init(params)
    WechatFriendsFetchWorker.perform_async(payload)
    secret = set_uin_secret_for(client.uin)
    publish('web_init', uin: client.uin, user: client.user, secret: secret)
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end

  def set_payload(payload)
    payload = payload.with_indifferent_access()
    @message_bus_token = payload.fetch(:message_bus_token)
    @params            = payload.slice(:login_info, :cookies)
  end
end
