class FacebookController < Messenger::MessengerController

  def index
    FacebookChat.process(fb_params)
    head :ok
  end

end