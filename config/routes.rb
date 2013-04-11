Coffeesharing::Application.routes.draw do

  root to:'pages#home'
  resources :places, only:[:index,:show]
  match 'posters' => 'pages#posters'
  match 'contributors' => 'pages#contributors'
  match 'press' => 'pages#press'

end
