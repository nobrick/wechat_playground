require Rails.root.join('db/elastic/migrate/create_index')

namespace :db do
  namespace :elastic do
    desc 'Recreate the Elasticsearch index'
    task :create_index => :environment do
      CreateIndex.new.run()
    end
  end
end
