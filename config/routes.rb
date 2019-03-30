Rails.application.routes.draw do
  root 'posts#index'
  get '/salut/(:name)', to: 'pages#salut', as: 'salut'
  get '/articles', to: 'posts#index', as: 'posts'
end
