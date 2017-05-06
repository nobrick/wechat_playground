class SessionsController < ApplicationController
  def new
    WechatQrWorker.perform_async()
  end

  def show
  end

  def delete
  end
end
