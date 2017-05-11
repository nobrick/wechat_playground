module Elastic::Model
  class Client

    ## Readers

    def get(id, type_name)
      body = client.get(index: index_name, type: type_name, id: id)
      Elastic::Friend::Hit.new(body)
    end

    def search(params)
      client.search(params)
    end

    def get_mapping(params = {})
      client.indices.get_mapping({index: index_name}.merge(params))
    end

    ## Writers

    def refresh
      client.indices.refresh(index: index_name)
    end

    def index(type_name, body)
      client.index(index: index_name, type: type_name, body: body)
    end

    def update(id, type_name, body)
      client.update(index: index_name, type: type_name, id: id,
                    body: {doc: body})
    end

    def delete(id, type_name)
      client.delete(index: index_name, type: type_name, id: id)
    end

    def recreate_index(mappings)
      client.indices.delete(index: index_name) rescue false
      client.indices.create(index: index_name, body: {mappings: mappings})
    end

    ## Helpers

    def make_query(opts = {})
      body =
        if block_given?
          yield
        else
          {}
        end
      {index: index_name, size: default_size, body: body}.merge(opts)
    end

    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end

    def index_name
      @index_name ||= 'elastic_playground'
    end

    def default_size
      5_000
    end
  end
end
