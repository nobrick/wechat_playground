require 'wechat_client'

class WechatQrWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0, dead: false

  def perform(*args)
    client = WechatClient::Core.new()
    qr_url = client.get_qr_url()

    # TODO: Place a session token in the channel for multi-user security.
    MessageBus.publish("/channel", qr_url)
  end
end
