# Messenger::Engine.routes.draw do
#   root to: "messenger#validate"
# end

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "index#index"
  # mount Messenger::Engine, at: "/facebook"
  post 'facebook', to: "facebook#index"
  get 'facebook', to: "facebook#webhook"
  post 'facebook/webhook', to: "facebook#webhook"
  # get 'facebook/webhook', to: "facebook#webhook"
  get 'facebook/subscribe', to: "facebook#subscribe"
end

# Messenger::Engine.routes.draw do
#   get  :subscribe, to: "messenger#subscribe"
#   get  :webhook,   to: "messenger#validate"
# end
#
# Rails.application.routes.draw do
#   post 'messenger/webhook', to: "messenger#webhook"
# end
