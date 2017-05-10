module Elastic::Friend
  class Hit < Elastic::Model::Hit
    attr_accessor :matches
    attr_reader :hit

    import_fields(
      avatar_path: 'avatar_path',
      avatar_phash: 'avatar_phash',
      uin_belongs_to: 'uin_belongs_to',
      nick_name: 'NickName',
      remark_name: 'RemarkName',
      province: 'Province',
      city: 'City',
      desc: 'Signature',
      star_flag: 'StarFriend',
      gender: 'Sex'
    )

    def name_with_fallback
      if remark_name.blank?
        nick_name
      else
        remark_name
      end
    end

    def location
      "#{province} #{city}"
    end

    def star?(friend)
      star_flag == 1
    end

    def gender_in_human
      case gender
      when 1 then '男'
      when 2 then '女'
      else ''
      end
    end
  end
end
