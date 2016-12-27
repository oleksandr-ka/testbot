require "facebook/base"

class FacebookController < ActionController::API
  include Facebook::Base

  def index
    FacebookChat.process(params)
    head :ok
  end

end