class FacebookChat
  
  def self.process(fb_params)
    if fb_params.first_entry.callback.message?
      self.send_text_message(fb_params)
    end
  end

  def self.send_text_message(fb_params)

    p '!!!!!!!!!!!!!!!!!!!!!!!'
    p fb_params
    p '!!!!!!!!!!!!!!!!!!!!!!!'
    p fb_params.first_entry.callback
    p '!!!!!!!!!!!!!!!!!!!!!!!'
    p fb_params.first_entry
    p '!!!!!!!!!!!!!!!!!!!!!!!'

    sender_id = fb_params.first_entry.sender_id
    Messenger::Client.send(
      Messenger::Request.new(
        Messenger::Elements::Text.new(text: "Echo: #{fb_params.first_entry.callback.text}"),
        sender_id
      )
    )
  end
  
end
