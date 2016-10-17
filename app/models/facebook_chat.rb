require 'nlp'
require 'messenger_platform/entities/action'
require 'messenger_platform/entities/text_message'

module FacebookChat
  extend NLP
  extend self

  def process(params)
    p '============FB PARAMS====================='
    p params
    @params = MessengerPlatform::Parser.execute(params)[0]
    p MessengerPlatform::Parser.execute(params)
    p '============FB PARAMS====================='

    if @params[:type] == 'message'
      MessengerPlatform::Api.call(:action, @params[:from], 'typing_on')
      run_actions(@params[:from], @params[:text])
    end unless @params.blank?
  end

  def proccess_text(text, quickreplies, context)
    action = context.try(:[], 'action')
    if action && defined?("send_#{action}")
      send("send_#{action}", text, quickreplies, context)
    else
      send_text_message(text, quickreplies)
    end
  end

  def send_text_message(text, quickreplies = nil)

    # MessengerPlatform.payload(:generic, user_id, [
    #     {
    #         "title":"Classic White T-Shirt",
    #         "item_url":"https://petersfancyapparel.com/classic_white_tshirt",
    #       "image_url":"https://petersfancyapparel.com/classic_white_tshirt.png",
    #     "subtitle":"Soft white cotton t-shirt is back in style",
    #     "buttons":[
    #     {
    #         "type":"web_url",
    #         "url":"https://petersfancyapparel.com/classic_white_tshirt",
    #         "title":"View Item",
    #         "webview_height_ratio":"tall"
    #     }
    # ]+
    # }
    # ])

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

  def send_check_location(text, quickreplies, context)
    p '==========send_check_location============='
    p context
    p '==========send_check_location============='
    send_text_message(text, quickreplies)
  end

end
