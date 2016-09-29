require "nlp"

class FacebookChat
  extend NLP

  class << self

    def process(fb_params)
      @params = fb_params
      p '=================FB_ECHO============'
      p @params.first_entry.callback
      p (!!@params.first_entry.callback.respond_to?(:is_echo) && @params.first_entry.callback.is_echo)
      p '=================FB_ECHO============'
      if @params.first_entry.callback.message? && !(!!@params.first_entry.callback.respond_to?(:is_echo) && @params.first_entry.callback.is_echo)
        self.run_actions(@params.first_entry.sender_id, @params.first_entry.callback.text)
      end
    end

    def proccess_text(text)
      self.send_text_message(text)
    end

    def send_text_message(text)

      # p '!!!!!!!!!!!!!!!!!!!!!!!'
      # p fb_params
      # p '!!!!!!!!!!!!!!!!!!!!!!!'
      # p fb_params.first_entry.callback
      # p '!!!!!!!!!!!!!!!!!!!!!!!'
      # p fb_params.first_entry
      # p '!!!!!!!!!!!!!!!!!!!!!!!'

      Messenger::Client.send(
          Messenger::Request.new(
              Messenger::Elements::Text.new(text: text),
              @params.first_entry.sender_id
          )
      )
    end
  end
end
