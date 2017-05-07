require 'wechat_client'

class WechatQrWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0, dead: false

  def perform(*args)
    qr_url = client.get_qr_url()

    # TODO: Place a session token in the channel for multi-user security.
    MessageBus.publish("/channel", {status: 'get_qr', url: qr_url}.to_json)
    WechatLoginCheckWorker.perform_async(client.uuid)
  end

  private

  def client
    @client ||= WechatClient::Core.new()
  end
end
