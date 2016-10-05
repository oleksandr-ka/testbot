module MessengerPlatform
  module Entities
    class Action < Message

      def body_params(action)
        auth_params.merge(sender_action: action)
      end
    end
  end
end
