module Messenger
  class Action
    def initialize(action, recipient_id)
      @recipient_id = recipient_id
      @action = action
      @body = body
    end

    def build
      return @body
    end

    def body
      {
          recipient: { id: @recipient_id },
          sender_action: @action
      }
    end
  end
end
