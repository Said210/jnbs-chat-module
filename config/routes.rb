Rails.application.routes.draw do
  resources :messages
    get '/api/get/messages/:id/:me' => 'messages#history'

    get '/api/get/:id/talked_with' => 'messages#has_talked_with'

    get '/message/:id' => 'messages#index'
    get '/listen/:id' => 'messages#profile_chat_monitor'
    post '/api/message/send' => 'messages#create' # Sends a message
    get '/live/:id/:me' => 'messages#live'
end
