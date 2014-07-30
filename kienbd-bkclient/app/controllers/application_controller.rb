class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  require 'pry'
  include ApplicationHelper

  # before_filter :authenticate_user!
  before_filter :change_locale

  #def devise_parameter_sanitizer
  #  if resource_class == User
  #    User::ParameterSanitizer.new(User, :user, params)
  #  else
  #    super
  #  end
  #end

  def change_locale
   I18n.locale= :vi
  end
  def setup_cas_user
      # save the login_url into an @var so that we can later use it in views (eg a login form)
      #@login_url = CASClient::Frameworks::Rails::Filter.login_url(self)
      return unless session[:cas_user].present?
      return if user_signed_in?

      # so now we go find the user in our db
      @current_user = User.find_by_email(session[:cas_user])
      sign_in(@current_user) if @current_user.present?
  end

end
