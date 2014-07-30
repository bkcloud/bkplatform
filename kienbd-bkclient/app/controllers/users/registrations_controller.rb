class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configured_permitted_parameters, if: :devise_controller?

  def new
    if params[:redirect_url]
        session[:redirect_url] = params[:redirect_url]
    else
	session[:redirect_url] = nil
    end
    super
  end

  def create
	super
	if resource.save
		session[:redirect_url] = nil
	end
  end
  
  protected
	#do after sign up
  def after_sign_up_path_for(resource)
    if session[:redirect_url].nil?
	super
    else
        path = session[:redirect_url]
	session[:redirect_url] = nil
        return path
    end
  end

  def sign_up(resource_name, resource)
    if session[:redirect_url].nil?
	super
    else
        path = session[:redirect_url]
        true
    end
  end

    # do after update
    def after_update_path_for(resource)
      edit_user_registration_path
    end

 # do after sign_in
  def after_sign_in_path_for(resource)
    if request.path_info == "/users/sign_in" || resource.class == User
      # home_index_path
      if resource.instance.nil?
        new_instance_path
      else
        instance_path(resource.instance.id)
      end
    elsif request.path_info == "/admins/sign_in" || resource.class == Admin
      admin_page_path
    end
  end

  # do after sign_out
  def after_sign_out_path_for(resource)
    if request.path_info == "/users/sign_out"
      new_user_session_path
    elsif request.path_info == "/admins/sign_out"
      new_admin_session_path
    end
  end

  def configured_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:username, :phone, :email, :password, :password_confirmation)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:username, :phone, :email, :password, :password_confirmation, :current_password)
    end
  end 

end
