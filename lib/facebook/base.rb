module Facebook
  module Base

    def webhook
      if verify_token_valid? && access_token_valid?
        render json: params["hub.challenge"]
      elsif !verify_token_valid?
        render json: 'Invalid verify token'
      else
        render json: 'Invalid page access token'
      end
    end

    def subscribe
      activate_bot
    end

    private

    def activate_bot
      Typhoeus.post("#{MessengerPlatform::Config.end_point}/me/subscribed_apps?access_token=#{MessengerPlatform::Config.token}")
    end

    def access_token_valid?
      begin
        JSON.parse(Typhoeus.get("#{MessengerPlatform::Config.end_point}/me/subscribed_apps?access_token=#{MessengerPlatform::Config.token}").body).key?('data')
      rescue
        return false
      end
    end

    def verify_token_valid?
      params["hub.verify_token"] == 'testbot'
    end

  end
end