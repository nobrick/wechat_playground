require 'wechat_client'

class WechatContactProcessWorker
  include Sidekiq::Worker
  include AvatarProcesser
  include ContactProcessedCounter
  include MessageBusHelper
  sidekiq_options retry: 10, dead: false
  sidekiq_retry_in {|_count| 1}

  attr_reader :message_bus_token, :login_info, :params, :uin

  def perform(payload, contact)
    set_payload(payload)
    set_py_fallback!(contact)
    save_avatar!(contact)
    index_contact(contact)
    publish_contact(contact)
  end
  
  private

  def index_contact(contact)
    elastic_friend.index_cache(uin, contact)
  end

  def publish_contact(contact)
    name = contact['RemarkName']
    name = contact['NickName'] if name.blank?
    publish('process_contact', name: name, count: incr_processed_count(uin))
  end

  def set_py_fallback!(contact)
    value = contact['RemarkPYQuanPin']
    value = contact['PYQuanPin'] if value.blank?
    contact['py_fallback'] = value
  end

  def elastic_friend
    @elastic_friend ||= Elastic::Friend::Client.new()
  end

  def client
    @client ||= WechatClient::Core.new()
  end

  def set_payload(payload)
    payload = payload.with_indifferent_access()
    @message_bus_token = payload.fetch(:message_bus_token)
    @login_info        = payload.fetch(:login_info)
    @params            = payload.slice(:login_info, :cookies)
    @uin               = client.uin_from_login_info(login_info)
  end
end
