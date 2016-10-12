require 'nlp'
require 'messenger_platform/entities/action'
require 'messenger_platform/entities/text_message'

class FacebookChat
  extend NLP

  class << self

    def process(params)
      p '============FB PARAMS====================='
      p params
      @params = MessengerPlatform::Parser.execute(params)[0]
      p MessengerPlatform::Parser.execute(params)
      p '============FB PARAMS====================='

      if @params[:type] == 'message'
        MessengerPlatform::Api.call(:action, @params[:from], 'typing_on')
        self.run_actions(@params[:from], @params[:text])
      end unless @params.blank?
    end

    def proccess_text(text, quickreplies)
      self.send_text_message(text, quickreplies)
    end

    def send_text_message(text, quickreplies = nil)
      params = {
          text: text
      }
      unless quickreplies.blank?
        params[:quick_replies] = []
        quickreplies.each do |reply|
          params[:quick_replies] << {
            content_type: 'text',
            title: reply,
            payload: 'SENDTEXT'
          }
        end

      end
      MessengerPlatform::Api.call(:text_message, @params[:from], params)
    end
  end
end
