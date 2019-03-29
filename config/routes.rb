Rails.application.routes.draw do
  get '/salut/(:name)', to: 'pages#salut', as: 'salut'
  root 'pages#salut'
end
