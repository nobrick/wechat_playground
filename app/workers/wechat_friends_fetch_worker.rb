require 'wechat_client'

class WechatFriendsFetchWorker
  include Sidekiq::Worker
  include MessageBusHelper
  sidekiq_options retry: 0, dead: false
  attr_accessor :message_bus_token

  def perform(message_bus_token, login_info)
    self.message_bus_token = message_bus_token
    client.get_contact(login_info: login_info)
    publish('fetch_friends', friends: client.friends)
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end
end
