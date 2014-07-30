class User::ParameterSanitizer < Devise::ParameterSanitizer
    private
    def sign_up
        default_params.permit(:username,:phone, :email, :password, :password_confirmation)
    end
    def create
        default_params.permit(:username,:phone, :email, :password, :password_confirmation)
    end
    def account_update
      default_params.permit(:phone, :password, :password_confirmation, :current_password)
    end
end
