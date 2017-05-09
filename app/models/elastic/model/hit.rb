module Elastic::Model
  class Hit
    cattr_reader :fields
    attr_reader :hit

    def self.import_fields(definitions)
      @@fields = definitions
      definitions.each do |method, name|
        define_method(method) do
          fetch(name)
        end
      end
    end

    def initialize(hit)
      @hit = hit
    end

    def id
      hit['_id']
    end

    def score
      hit['_score']
    end

    def index_name
      hit['_index']
    end

    def type_name
      hit['_type']
    end

    def fetch(key)
      hit['_source'][key]
    end

    def source
      hit['_source']
    end
  end
end
