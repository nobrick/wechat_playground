class CreateIndex
  def run
    friend_client.recreate_index(mappings)
  end

  private

  def mappings
    {
      cache_type     => friend_mapping_body,
      confirmed_type => friend_mapping_body
    }
  end

  def friend_mapping_body
    {
      "properties"=> {
        "Alias"            => {"type" => "keyword"},
        "AppAccountFlag"   => {"type" => "long"},
        "AttrStatus"       => {"type" => "long"},
        "ChatRoomId"       => {"type" => "long"},
        "City"             => {"type" => "keyword"},
        "ContactFlag"      => {"type" => "long"},
        "DisplayName"      => {"type" => "keyword"},
        "EncryChatRoomId"  => {"type" => "keyword"},
        "HeadImgUrl"       => {"type" => "keyword"},
        "HideInputBarFlag" => {"type" => "long"},
        "IsOwner"          => {"type" => "long"},
        "KeyWord"          => {"type" => "keyword"},
        "MemberCount"      => {"type" => "long"},
        "NickName"         => {"type" => "keyword"},
        "OwnerUin"         => {"type" => "long"},
        "PYInitial"        => {"type" => "keyword"},
        "PYQuanPin"        => {"type" => "keyword"},
        "Province"         => {"type" => "keyword"},
        "RemarkName"       => {"type" => "keyword"},
        "RemarkPYInitial"  => {"type" => "keyword"},
        "RemarkPYQuanPin"  => {"type" => "keyword"},
        "Sex"              => {"type" => "long"},
        "Signature"        => {"type" => "keyword"},
        "SnsFlag"          => {"type" => "long"},
        "StarFriend"       => {"type" => "long"},
        "Statues"          => {"type" => "long"},
        "Uin"              => {"type" => "long"},
        "UniFriend"        => {"type" => "long"},
        "UserName"         => {"type" => "keyword"},
        "VerifyFlag"       => {"type" => "long"},
        "avatar_base64"    => {"type" => "keyword"},
        "avatar_path"      => {"type" => "keyword"},
        "avatar_phash"     => {"type" => "keyword"},
        "model"            => {"type" => "keyword"},
        "uin_belongs_to"   => {"type" => "keyword"}
      }
    }
  end

  def cache_type
    friend_client.type_name_for_cache
  end

  def confirmed_type
    friend_client.type_name_for_confirmed
  end

  def friend_client
    @friend_client ||= ::Elastic::Friend::Client.new()
  end
end
