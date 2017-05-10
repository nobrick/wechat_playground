class FriendsController < ApplicationController
  before_action :login_required
  helper :friends

  # GET /friends
  def index
    @hits = friend_client.search_confirmed(current_uin)
  end

  # GET /friends/:id
  def show
  end

  private

  def friend_client
    @friend_client ||= Elastic::Friend::Client.new()
  end
end
