module FriendsHelper
  def avatar_tag(friend_hit, opts = {})
    default = {height: 48, width: 48, class: 'avatar'}
    image_tag(friend_hit.avatar_path, default.merge(opts))
  end
end
