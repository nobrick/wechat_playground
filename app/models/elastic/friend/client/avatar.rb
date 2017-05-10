module Elastic::Friend::Client::Avatar
  def self.cp_cache_avatar_to_confirmed(cache_hit, match_id)
    from_avatar_path = "public" + cache_hit.avatar_path
    to_avatar_path = confirmed_avatar_path(cache_hit.uin_belongs_to, match_id)
    from_pathname = Rails.root.join(from_avatar_path)
    to_pathname = Rails.root.join(to_avatar_path)
    FileUtils.cp(from_pathname, to_pathname)
    to_avatar_path[to_avatar_path.index("/")..-1]
  end

  private

  def self.mkdir_confirmed(uin)
    Rails.root.join("public/avatars/confirmed/#{uin}").mkdir() rescue false
  end

  def self.confirmed_avatar_path(uin, match_id)
    "public/avatars/confirmed/#{uin}/#{match_id}.jpg"
  end
end
