class ContactSyncsController < ApplicationController
  before_action :login_required
  helper :friends

  # Provides user interfaces for synchronizing friends.
  #
  # GET /contact_sync/new
  def new
    @unmatched_hits    = []
    @matched_hits      = []
    @questionable_hits = []
    search_and_match_in_cache do |hit, matches|
      case matches.count
      when 0 then @unmatched_hits << hit
      when 1 then @matched_hits   << hit
      else @questionable_hits     << hit
      end
    end
    set_counts
  end

  # Links a matched cache friend to an existing confirmed friend.
  #
  # POST /contact_sync
  def create
    cache_id = params[:cache_id]
    match_id = params[:match_id]
    cache_hit = friend_client.get(cache_id, cache_type)
    if cache_hit.uin_belongs_to != current_uin()
      redirect_to root_url, status: 403
    else
      friend_client.confirm_cache_hit(cache_hit, match_id)
      friend_client.refresh()
      redirect_to friends_url
    end
  end

  # Imports all cache friends who has no high-score match as newly added
  # confirmed friends.
  #
  # POST /contact_sync/import_unmatched
  def import_unmatched
    search_and_match_in_cache do |hit, matches|
      if matches.blank?
        friend_client.index_confirmed(hit.uin_belongs_to, hit.source)
        friend_client.delete(hit.id, cache_type)
      end
    end
    friend_client.refresh()
    redirect_to friends_url
  end

  # Acknowledges all cache friends who has only one high-score match and
  # updates the associated confirmed friends.
  #
  # POST /contact_sync/acknowledge_matched
  def acknowledge_matched
    search_and_match_in_cache do |hit, matches|
      if matches.count == 1
        friend_client.update(matches.first.id, confirmed_type, hit.source)
        friend_client.delete(hit.id, cache_type)
      end
    end
    friend_client.refresh()
    redirect_to friends_url
  end

  private

  def search_and_match_in_cache
    friend_client.search_cache(current_uin()).each do |hit|
      hit.matches = friend_client.match_confirmed(hit)
      yield hit, hit.matches if block_given?
    end
  end

  def set_counts
    @unmatched_count    = @unmatched_hits.count
    @matched_count      = @matched_hits.count
    @questionable_count = @questionable_hits.count
  end

  def cache_type
    friend_client.type_name_for_cache
  end

  def confirmed_type
    friend_client.type_name_for_confirmed
  end

  def friend_client
    @friend_client ||= Elastic::Friend::Client.new()
  end
end
