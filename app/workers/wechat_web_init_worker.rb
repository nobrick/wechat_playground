require 'wechat_client'

class WechatWebInitWorker
  include Sidekiq::Worker
  include MessageBusHelper
  include Login
  sidekiq_options retry: 0, dead: false
  attr_accessor :message_bus_token

  def perform(message_bus_token, login_info)
    self.message_bus_token = message_bus_token
    client.web_init(login_info: login_info)
    WechatFriendsFetchWorker.perform_async(message_bus_token, login_info)
    secret = set_uid_secret_for(client.uin)
    publish('web_init', uin: client.uin, user: client.user, secret: secret)
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end
end
