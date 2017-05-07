class WechatFriendsFetchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0, dead: false

  def perform(login_info)
    client.get_contact(login_info: login_info)
    payload = {status: 'fetch_friends', friends: client.friends}.to_json
    MessageBus.publish("/channel", payload)
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end
end
