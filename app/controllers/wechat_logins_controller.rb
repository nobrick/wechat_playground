require 'wechat_client'

class WechatLoginsController < ApplicationController
  before_action :no_login_required, only: :download_qr

  # GET /wechat_login/new
  def new
    qr_url = client.get_qr_url()
    WechatLoginCheckWorker.perform_async(message_bus_token, client.uuid)
    render json: {status: 200, url: qr_url}
  end

  private

  def client
    @client ||= WechatClient::Core.new()
  end

  def message_bus_token
    session[:message_bus_token]
  end
end
