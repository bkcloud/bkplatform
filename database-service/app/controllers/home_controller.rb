class HomeController < ApplicationController

  #before_filter :signed_in_user?,:except => [:auth]
  before_filter CASClient::Frameworks::Rails::Filter,:except => [:welcome, :unauthorized, :error]
  before_filter CASClient::Frameworks::Rails::GatewayFilter,:only => [:welcome, :unauthorized, :error]
  #before_filter :setup_cas_user,:except => [:welcome, :unauthorized, :error]
  before_filter :setup_cas_user

  def setup_cas_user
      # save the login_url into an @var so that we can later use it in views (eg a login form)
      #@login_url = CASClient::Frameworks::Rails::Filter.login_url(self)
      puts "ALOHA"
      return unless session[:cas_user].present?
      return if user_signed_in?

      # so now we go find the user in our db
      @current_user = User.find_by_email(session[:cas_user])
      if @current_user.nil?
        user = User.new(:email => session[:cas_user],
                        :password => Devise.friendly_token[10,20])
        if user.save
          sleep(1)
          sign_in(user)
        else
          return_path = APP_CONFIG["url"]
          CASClient::Frameworks::Rails::Filter.logout(self,return_path)
        end
      else
        sign_in(@current_user) if @current_user.present?
      end
      Labrador::Session.clear_all
      current_user.database_connections.each do |db|
        db_params = db.attributes.except("created_at", "updated_at", "user_id", "id").symbolize_keys
        app = Labrador::App.new(db_params)
        Labrador::Session.add db_params
      end
  end

  def logout
    # optionally do some local cleanup here
    #return_path = "#{request.protocol}#{request.host_with_port}"
    return_path = APP_CONFIG["url"]
    CASClient::Frameworks::Rails::Filter.logout(self,return_path)
    Labrador::Session.clear_all
  end

  def welcome
    #@return_path = "#{request.protocol}#{request.host_with_port}"
    @return_path = APP_CONFIG["url"]
    redirect_to '/' if user_signed_in?
  end

  def index

  end

  def signed_in_user?
    unless user_signed_in?
      redirect_to new_user_registration_path
    end
  end

end
