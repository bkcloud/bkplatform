Elrails::Application.routes.draw do
  devise_for :users,
    :skip =>[:registrations,:sessions],
    :controllers => {
      :registrations => "users/registrations",
      :sessions => "users/sessions"
  }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#welcome'
  #root 'home#index'

  get 'index' => 'home#index'

  get 'elfinder' => 'home#elfinder'
  post 'elfinder' => 'home#elfinder'
  put 'elfinder' => 'home#elfinder'
  post 'dbticket' => 'home#dbticket'
  post 'synkey' => 'home#synkey'
  get 'locale' => 'home#locale'

  get '/vendor/mounts/:user_hash/.thumbs/:id' =>  'home#thumbs'
  get '/vendor/mounts/:user_hash/:preview' => 'home#previews',constraints: {
    preview: /.*/
  }
  get '/download' => 'home#download'
  get '/createContainer' => 'home#createContainer'
  get '/auth' => 'home#auth'
  get '/install' => 'home#install'
  get 'logout' => 'home#logout'

  get '/shares/:id' => 'file_maps#show'
  resources :file_maps

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
