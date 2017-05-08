class Elastic::Friend
  attr_accessor :client, :index_name

  ## Writers

  def batch_index_cache(uin, friends_body, opts = {})
    clear_cache(uin) if opts.fetch(:clear_cache, true)
    friends_body.each do |body|
      Rails.logger.info index_cache(uin, body)
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

  ## Readers

  def index_exists?(name = self.index_name)
    client.indices.exists?(index: name)
  end

  def search_cache(uin)
    client.search(query_params_for_cache(uin))
  end

  ## Helpers

  def client
    @client ||= Elasticsearch::Client.new(log: true)
  end

  def index_name
    @index_name ||= 'elastic_playground'
  end

  def query_params_for_cache(uin)
    body = {query: {term: {uin_belongs_to: uin}}}
    {index: index_name, type: type_name_for_cache, body: body, size: 5000}
  end

  private

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
