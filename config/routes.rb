Coffeesharing::Application.routes.draw do

  root to:'pages#home'
  match 'contributors' => 'pages#contributors'
  match 'press' => 'pages#press'
  resources :places, only:[:index,:show]

end
