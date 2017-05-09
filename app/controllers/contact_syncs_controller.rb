class ContactSyncsController < ApplicationController
  before_action :login_required
  helper :friends

  # GET /contact_sync/new
  def new
    @friend_hits = friend_client.search_cache(session[:uin])
  end

  # POST /contact_sync
  def create
  end

  private

  def friend_client
    @friend_client ||= Elastic::Friend::Client.new()
  end
end
