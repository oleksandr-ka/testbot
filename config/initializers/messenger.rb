Messenger.configure do |config|
  config.verify_token      = 'testbot' #will be used in webhook verifiction
  config.page_access_token = 'EAAThNY2jwBUBAAozpvVXoPwx0ZCFtTO0ZBRfmoMXNbbctl7R8MUEOZAEgDG4KPtwgdIuZAmpSykcZB88WO6B0wEjWUiZBfoNUPui9ggCm6RTqvWJmYbVYyjqBc3qG3edAB7hx0WllGXrG5sw2XZBHdlyjKGl2x17Px7Chgtk0uNNwZDZD'
end

module Messenger
  module Parameters
    class Messaging
      attr_accessor :sender_id, :recipient_id, :callback

      def initialize(sender:, recipient:, timestamp: nil, message: nil, delivery: nil, postback: nil, optin: nil, read: nil, account_linking: nil, quick_reply: nil)
        @sender_id    = sender['id']
        @recipient_id = recipient['id']
        @callback     = set_callback(message: message, delivery: delivery, postback: postback, optin: optin, read: read, account_linking: account_linking)
      end

      def set_callback(callbacks)
        type = callbacks.select { |_, v| v.present? }.keys.first
        @callback = constant(type).new(callbacks[type].symbolize_keys)
      end

      private

      def constant(symbol)
        "Messenger::Parameters::#{symbol.to_s.camelize}".constantize
      end
    end
  end
end