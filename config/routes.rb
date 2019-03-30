Rails.application.routes.draw do
  root 'posts#index'
  get '/salut/(:name)', to: 'pages#salut', as: 'salut'
  resources :posts
  resources :categories
end
