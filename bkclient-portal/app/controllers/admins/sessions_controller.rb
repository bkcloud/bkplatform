class Admins::SessionsController < Devise::SessionsController
 
  protected
    # do after sign_in
  def after_sign_in_path_for(resource)
    if request.path_info == "/admins/sign_in" || resource.class == Admin
      admin_page_path
    end
  end

  # do after sign_out
  def after_sign_out_path_for(resource)
    if request.path_info == "/admins/sign_out"
      new_admin_session_path
    end
  end

end
