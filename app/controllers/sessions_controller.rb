class SessionsController < ApplicationController
  before_action :no_login_required, only: [:new, :create]
  before_action :login_required,    only: [:show, :destroy]

  # GET /session/new
  def new
  end

  # POST /session
  def create
    uin = params['uin']
    secret = params['secret']
    if login_as(uin, secret)
      render json: {status: 200}
    else
      render json: {status: 403}
    end
  end

  # DELETE /session
  def destroy
    logout()
    redirect_to new_session_url
  end

  private

  def set_message_bus_token
    session[:message_bus_token] = SecureRandom.hex(10)
  end
end
