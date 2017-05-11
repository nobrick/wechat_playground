module Elastic::Friend::Client::Avatar
  def self.cp_cache_avatar_to_confirmed(cache_hit, filename)
    filename = SecureRandom.hex if filename == :random
    from_avatar_path = "public" + cache_hit.avatar_path
    to_avatar_path = confirmed_avatar_path(cache_hit.uin_belongs_to, filename)
    from_pathname = Rails.root.join(from_avatar_path)
    to_pathname = Rails.root.join(to_avatar_path)
    avatar_path_field = to_avatar_path[to_avatar_path.index("/")..-1]
    FileUtils.cp(from_pathname, to_pathname)
    {
      field_name(:avatar_path) => avatar_path_field,
      field_name(:avatar_phash) => cache_hit.avatar_phash
    }
  end

  private

  def self.mkdir_confirmed(uin)
    Rails.root.join("public/avatars/confirmed/#{uin}").mkdir() rescue false
  end

  def self.confirmed_avatar_path(uin, filename)
    "public/avatars/confirmed/#{uin}/#{filename}.jpg"
  end

  def self.field_name(name)
    Elastic::Friend::Hit.fields[name]
  end
end
