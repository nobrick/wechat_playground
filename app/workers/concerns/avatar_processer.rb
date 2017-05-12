module MessageBusHelper
  extend ActiveSupport::Concern

  def mkdir_for_avatars
    path = Rails.root.join("public/avatars/cache/#{uin}")
    FileUtils.rm(Dir.glob(path.join("*.jpg")))
    path.mkdir() rescue false
  end

  def save_avatar!(contact)
    relative_path = "public/avatars/cache/#{uin}/#{SecureRandom.uuid}.jpg"
    avatar_path = Rails.root.join(relative_path).to_s
    File.open(avatar_path, 'wb') do |file|
      file.write(client.get_avatar(contact, params))
    end
    contact['avatar_phash'] = get_avatar_phash(avatar_path).to_s
    contact['avatar_path'] = relative_path[relative_path.index("/")..-1]
  end

  private

  def get_avatar_phash(avatar_path)
    Phashion::Image.new(avatar_path).fingerprint
  end

  def client
    @client ||= WechatClient::Core.new()
  end
end
