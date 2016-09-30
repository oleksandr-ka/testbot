require 'messenger/components/element'

module Messenger
  module Elements
    class QuickText
      include Components::Element

      def initialize(text:, quick_replies: nil)
        @text = text
        @quick_replies = quick_replies
      end

    end
  end
end
