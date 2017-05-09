require 'wechat_client'

class WechatFriendsFetchWorker
  include Sidekiq::Worker
  include MessageBusHelper
  sidekiq_options retry: 0, dead: false
  attr_reader :message_bus_token, :login_info, :params, :uin

  def perform(payload)
    set_payload(payload)
    client.get_contact(params)
    client.friends = client.friends.first(20) if test_mode?
    save_avatars()
    index_friends()
    publish('fetch_friends', friends: client.friends)
  end
  
  private

  def index_friends(friends = client.friends)
    logger.info("Index friends...")
    elastic_friend.batch_index_cache(uin, friends)
  end

  def save_avatars(friends = client.friends)
    logger.info("Downloading avatars...")
    mkdir_for_avatars()
    friends.map! do |contact|
      relative_path = generate_avatar_path()
      avatar_path = Rails.root.join(relative_path).to_s
      data = download_avatar(avatar_path, contact)
      contact['avatar_phash'] = get_avatar_phash(avatar_path).to_s
      contact['avatar_path'] = relative_path[relative_path.index("/")..-1]
      contact
    end
  end

  def download_avatar(path, contact)
    data = client.get_avatar(contact, params)
    File.open(path, 'wb') do |file|
      file.write(data)
    end
    data
  end

  def get_avatar_phash(avatar_path)
    Phashion::Image.new(avatar_path).fingerprint
  end

  def mkdir_for_avatars
    path = Rails.root.join("public/avatars/cache/#{uin}")
    FileUtils.rm(Dir.glob(path.join("*.jpg")))
    path.mkdir() rescue false
  end

  def generate_avatar_path
    "public/avatars/cache/#{uin}/#{SecureRandom.uuid}.jpg"
  end

  def elastic_friend
    @elastic_friend ||= Elastic::Friend::Client.new()
  end

  def client
    @client ||= WechatClient::Core.new()
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
