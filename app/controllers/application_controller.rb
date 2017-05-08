class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include Login
  helper_method :login?
end
