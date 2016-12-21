module MessengerPlatform
  module Entities
    class WelcomeButton < Welcome

      def call(action)
        params = {
          access_token: Config.token,
          setting_type: 'call_to_actions',
          thread_state: 'new_thread',
          call_to_actions: [
            {payload: action}
          ]
        }

        Typhoeus.post("#{Config.end_point}/me/thread_settings", body: params)
      end

    end
  end
end