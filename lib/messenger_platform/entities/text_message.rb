module MessengerPlatform
  module Entities
    class TextMessage < Message

      def body_params(text)
        text_params = if text.instance_of?(String)
          {text: text}
        else
          text
        end
        auth_params.merge(message_params(text_params))
      end
    end
  end
end