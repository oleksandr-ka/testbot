require "nlp"
# require "messenger/action"
# require "messenger/components/elements/quick_text"

class FacebookChat
  extend NLP

  class << self

    def process(params)
      p '============FB PARAMS====================='
      p params
      @params = MessengerPlatform::Parser.execute(params)[0]
      p MessengerPlatform::Parser.execute(params)
      p '============FB PARAMS====================='
      # @params = fb_params
      # p '=================FB_ECHO============'
      # p @params.first_entry
      # p @params.first_entry.callback
      # p (!!@params.first_entry.callback.respond_to?(:is_echo) && !!@params.first_entry.callback.is_echo)
      # p '=================FB_ECHO============'
      # if @params.first_entry.callback.message? && !(!!@params.first_entry.callback.respond_to?(:is_echo) && !!@params.first_entry.callback.is_echo)
      #   Messenger::Client.send(
      #       Messenger::Action.new(
      #           'typing_on',
      #           @params.first_entry.sender_id
      #       )
      #   )
      #   self.run_actions(@params.first_entry.sender_id, @params.first_entry.callback.text)
      # end
      if @params[:type] == 'message'
        self.run_actions(@params[:from], @params[:text])
      end unless @params.blank?
    end

    def proccess_text(text)
      self.send_text_message(text)
    end

    def send_text_message(text)

      MessengerPlatform.text(@params[:from], text)
      # Messenger::Client.send(
      #     Messenger::Request.new(
      #         Messenger::Elements::QuickText.new(text: text),
      #         @params.first_entry.sender_id
      #     )
      # )
    end
  end
end
