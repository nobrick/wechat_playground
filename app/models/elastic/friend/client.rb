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
      process_result(search(query_params(uin, type_name_for_cache)))
    end

    def search_confirmed(uin, opts = {})
      process_result(search(query_params(uin, type_name_for_confirmed)))
    end

    def match_confirmed(hit, term_importance = self.term_importance, opts = {})
      conditions =
        term_importance.map do |term_key, boost|
          query_term_on_hit_value(term_key, hit, boost)
        end
      query =
        make_query(type: type_name_for_confirmed, size: 5) do
          {
            query: {
              bool: {
                filter: query_term_on_hit_value(:uin_belongs_to, hit),
                should: conditions.compact(),
                minimum_should_match: 1
              }
            }
          }
        end
      matches = process_result(search(query))
      threshold = 17
      if matches.count >= 2
        threshold = [matches.first.score / 1.618, threshold].max
      end
      matches.select {|m| m.score >= threshold}
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
      client.delete_by_query(query_params(uin, type_name_for_cache))
    end

    def index_cache(uin, friend_body)
      friend_body.merge!(uin_belongs_to: uin, model: 'cache')
      index(type_name_for_cache, friend_body)
    end

    def index_confirmed(uin, friend_body)
      friend_body.merge!(uin_belongs_to: uin, model: 'confirmed')
      index(type_name_for_confirmed, friend_body)
    end

    def confirm_cache_hit(cache_hit, opts = {})
      match_id = opts[:match_id]
      avatar_attrs =
        Elastic::Friend::Client::Avatar
          .cp_cache_avatar_to_confirmed(cache_hit, match_id || :random)
      source = cache_hit.source.merge(avatar_attrs)
      if opts.fetch(:method) == :update
        update(match_id, type_name_for_confirmed, source)
      else
        index_confirmed(cache_hit.uin_belongs_to, source)
      end
      delete(cache_hit.id, type_name_for_cache)
    end

    ## Helpers

    def process_result(result)
      result['hits']['hits'].map {|h| Elastic::Friend::Hit.new(h)}
    end

    def term_importance
      @term_importance ||= {
        avatar_phash: 32,
        remark_name: 24,
        nick_name: 16,
        desc: 8,
        province: 1,
        city: 1,
        star_flag: 1,
        gender: 1
      }
    end

    def type_name_for_cache
      'friend_cache'
    end

    def type_name_for_confirmed
      'friend_confirmed'
    end

    private

    def query_params(uin, type_name)
      make_query(type: type_name) do
        {query: query_term(:uin_belongs_to, uin)}
      end
    end

    def query_term(key, value, boost = 1.0)
      {
        constant_score: {
          filter: {
            term: {self.class.fields[key] => value}
          },
          boost: boost
        }
      }
    end

    def query_term_on_hit_value(key, hit, boost = 1.0)
      value = hit.fetch(self.class.fields[key])
      return nil if value.blank?
      query_term(key, value, boost)
    end
  end
end
