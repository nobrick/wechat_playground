class WechatWebInitWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0, dead: false

  def perform(login_info)
    client.web_init(login_info: login_info)
    payload = {status: 'web_init', uin: client.uin, user: client.user}.to_json
    WechatFriendsFetchWorker.perform_async(login_info)
    MessageBus.publish("/channel", payload)
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end
end
