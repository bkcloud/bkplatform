Labrador::Application.routes.draw do

  devise_for :users,
    :skip =>[:registrations,:sessions],
    :controllers => {
      :registrations => "users/registrations",
      :sessions => "users/sessions"
  }

  # root to: 'pages#home'
  root to: redirect("/#{I18n.default_locale}", status: 302), as: :redirected_root
  # root to: 'home#welcome'
  delete 'logout' => 'home#logout'

  scope "/:locale", locale: /#{I18n.available_locales.join("|")}/ do
    #get 'welcome' => 'home#welcome'
    get 'bkdatabase' => 'home#welcome', as: 'welcome'
    get '401', to: 'pages#unauthorized', as: 'unauthorized'
    get 'error', to: 'pages#error', as: 'error'
  end
  #get 'welcome' => 'home#welcome'
  get 'bkdatabase' => 'home#welcome'

  scope "data" do
    Labrador::Constants::ADAPTER_KEYS.each do |adapter|
      resources adapter, controller: 'data', adapter: adapter do
        collection do
          get :collections, action: 'collections'
          get :schema, action: 'schema'
          delete :droptable, action: 'droptable'
          post :createtable, action: 'createtable'
        end
      end
    end
  end

  delete 'data/dropdb', to: 'data#dropdb'

  scope "/:locale", locale: /#{I18n.available_locales.join("|")}/ do
    resources :database_connections
    root to: redirect("/%{locale}/database_connections/new", status: 302)
  end
  get '/:locale/*path', to: 'pages#home'
end
