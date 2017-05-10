module Elastic::Model
  class Client
    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end

    def refresh
      client.indices.refresh(index: index_name)
    end

    def make_query(opts = {})
      body =
        if block_given?
          yield
        else
          {}
        end
      {index: index_name, size: default_size, body: body}.merge(opts)
    end

    def index_name
      @index_name ||= 'elastic_playground'
    end

    def default_size
      5_000
    end
  end
end
