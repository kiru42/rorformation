Rails.application.routes.draw do
  get '/salut', to: 'pages#salut'
  root 'pages#salut'
end
