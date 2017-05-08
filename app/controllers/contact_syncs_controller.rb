class ContactSyncsController < ApplicationController
  before_action :login_required

  # GET /contact_sync/new
  def new
    uin = session[:uin]
    result = elastic_friend.search_cache(uin)
    @text = result["hits"]["hits"].map {|e| e["_source"]["NickName"]}
    @count = @text.count
  end

  # POST /contact_sync
  def create
  end

  private

  def elastic_friend
    @elastic_friend ||= Elastic::Friend.new()
  end
end
