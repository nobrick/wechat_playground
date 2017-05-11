module Elastic::Friend::Client::Avatar
  def self.cp_cache_avatar_to_confirmed(cache_hit, filename)
    filename = SecureRandom.hex if filename == :random
    from_avatar_path = "public" + cache_hit.avatar_path
    to_avatar_path = confirmed_avatar_path(cache_hit.uin_belongs_to, filename)
    from_pathname = Rails.root.join(from_avatar_path)
    to_pathname = Rails.root.join(to_avatar_path)
    FileUtils.cp(from_pathname, to_pathname)
    to_avatar_path[to_avatar_path.index("/")..-1]
  end

  private

  def self.mkdir_confirmed(uin)
    Rails.root.join("public/avatars/confirmed/#{uin}").mkdir() rescue false
  end

  def self.confirmed_avatar_path(uin, filename)
    "public/avatars/confirmed/#{uin}/#{filename}.jpg"
  end
end
