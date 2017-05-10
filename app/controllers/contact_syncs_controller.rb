class ContactSyncsController < ApplicationController
  before_action :login_required
  helper :friends

  # GET /contact_sync/new
  def new
    friend_hits = friend_client.search_cache(session[:uin])
    friend_hits.each {|h| h.matches = friend_client.match_confirmed(h)}
    @unmatched_hits    = friend_hits.select {|h| h.matches.count == 0}
    @matched_hits      = friend_hits.select {|h| h.matches.count == 1}
    @questionable_hits = friend_hits.select {|h| h.matches.count >= 2}
    set_counts
  end

  # POST /contact_sync
  def create
  end

  private

  def set_counts
    @unmatched_count    = @unmatched_hits.count
    @matched_count      = @matched_hits.count
    @questionable_count = @questionable_hits.count
  end

  def friend_client
    @friend_client ||= Elastic::Friend::Client.new()
  end
end
