Coffeesharing::Application.routes.draw do

  # Main pages
  root to:'pages#home'
  resources :places, only:[:index,:show]
  match 'posters' => 'pages#posters'
  match 'contributors' => 'pages#contributors'
  match 'press' => 'pages#press'

  # Administration
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

end
