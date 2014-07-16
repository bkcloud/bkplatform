class Users::SessionsController < Devise::SessionsController

  # layout :layout_by_resource
  def new
    super
  end

  # def layout_by_resource
    # if devise_controller? && resource_name == :user
      # "users_forms"
    # else
      # "application"
    # end
  # end
end
