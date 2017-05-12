require 'wechat_client'

class WechatFriendsFetchWorker
  include Sidekiq::Worker
  include AvatarProcesser
  include ContactProcessedCounter
  include MessageBusHelper
  sidekiq_options retry: 0, dead: false
  attr_reader :message_bus_token, :login_info, :params, :uin

  def perform(payload)
    set_payload(payload)
    client.get_contact(params)
    client.friends = client.friends.first(20) if test_mode?
    mkdir_for_avatars()
    elastic_friend.clear_cache(uin)
    reset_processed_count(uin)
    publish('fetch_friends', count: client.friends.count)
    client.friends.each do |friend|
      WechatContactProcessWorker.perform_async(payload, friend)
    end
  end
  
  private

  def client
    @client ||= WechatClient::Core.new()
  end

  def elastic_friend
    @elastic_friend ||= Elastic::Friend::Client.new()
  end

  def set_payload(payload)
    payload = payload.with_indifferent_access()
    @message_bus_token = payload.fetch(:message_bus_token)
    @login_info        = payload.fetch(:login_info)
    @params            = payload.slice(:login_info, :cookies)
    @uin               = client.uin_from_login_info(login_info)
  end

  def test_mode?
    ENV['WC_TEST'] == '1'
  end
end
