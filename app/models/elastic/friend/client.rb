module Elastic::Friend
  class Client < Elastic::Model::Client

    def self.fields
      Elastic::Friend::Hit.fields
    end

    attr_accessor :term_importance

    ## Readers

    def index_exists?(name = self.index_name)
      client.indices.exists?(index: name)
    end

    def search_cache(uin, opts = {})
      process_result(client.search(query_params_for_cache(uin)))
    end

    def match_confirmed(hit, term_importance = self.term_importance)
      query =
        make_query(type: type_name_for_confirmed, size: 5) do
          {
            query: {
              bool: {
                filter:
                  query_term_on_hit_value(:uin_belongs_to, hit),
                should:
                  term_importance.map do |term_key, boost|
                    query_term_on_hit_value(term_key, hit, boost)
                  end
              }
            }
          }
        end
      process_result(client.search(query))
    end

    ## Writers

    def batch_index_cache(uin, friends_body, opts = {})
      clear_cache(uin) if opts.fetch(:clear_cache, true)
      friends_body.each do |body|
        index_cache(uin, body)
      end
    end

    def clear_cache(uin)
      return unless index_exists?
      client.delete_by_query(query_params_for_cache(uin))
    end

    def index_cache(uin, friend_body)
      friend_body.merge!(uin_belongs_to: uin, model: 'cache')
      index(type_name_for_cache, friend_body)
    end

    def index_confirmed(uin, friend_body)
      friend_body.merge!(uin_belongs_to: uin, model: 'confirmed')
      index(type_name_for_confirmed, friend_body)
    end

    ## Helpers

    def process_result(result)
      result['hits']['hits'].map {|h| Elastic::Friend::Hit.new(h)}
    end

    def term_importance
      @term_importance ||= {
        avatar_phash: 16,
        remark_name: 8,
        nick_name: 4,
        desc: 4,
        province: 1.5,
        city: 1.5,
        star_flag: 1,
        gender: 1
      }
    end

    private

    def query_params_for_cache(uin)
      make_query(type: type_name_for_cache) do
        {query: query_term(:uin_belongs_to, uin)}
      end
    end

    def query_term(key, value, boost = 1.0)
      {term: {self.class.fields[key] => {value: value, boost: boost}}}
    end

    def query_term_on_hit_value(key, hit, boost = 1.0)
      query_term(key, hit.fetch(self.class.fields[key]), boost)
    end

    def index(type_name, body)
      client.index(index: index_name, type: type_name, body: body)
    end

    def type_name_for_cache
      'friend_cache'
    end

    def type_name_for_confirmed
      'friend_confirmed'
    end
  end
end
