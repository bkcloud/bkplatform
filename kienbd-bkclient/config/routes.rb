Bkclient::Application.routes.draw do
  require 'sidekiq/web'
  devise_for :admins, :skip => [:registrations], :controllers => { :sessions => "admins/sessions" }
  devise_for :users, :controllers => { :registrations => "users/registrations" }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  devise_scope :user do
    root to: "home#index"
  end

  resources :home do
  end
  get 'confirmation' => "home#confirmation"
  get 'admin_page' => 'home#admin_page'
  get 'sync' => 'home#sync'
  get 'index' => 'home#index'
  #get 'welcome' => 'home#welcome'
  get 'bkclient' => 'home#welcome', as: 'welcome'
  get 'logout' => 'home#logout'

  # sync between cloud and portal
  # get 'templates/sync' => 'templates#sync'
  # get 'diskofferings/sync' => 'disk_offerings#sync'
  # get 'serviceofferings/sync' => 'service_offerings#sync'

  # mount Resque::Server, :at => "/resque"
  mount Sidekiq::Web, :at => "/sidekiq"

  resources :instances do
    member do
      get :viewSpiceWebSock
      get :approve
      get :send_mail
      get :start
      get :shutdown
      get :remove
    end
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
