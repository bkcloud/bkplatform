class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  include ApplicationHelper

  attr_accessor :applications

  before_action :set_locale
  before_filter :http_authenticate, except: [:unauthorized, :installation, :welcome]

  helper_method :exports, :current_app

  def after_sign_in_path_for(resource)
    Labrador::Session.clear_all
    current_user.database_connections.each do |db|
      db_params = db.attributes.except("created_at", "updated_at", "user_id", "id").symbolize_keys
      app = Labrador::App.new(db_params)
      Labrador::Session.add db_params
    end
    root_path
  end

  def after_sign_out_path_for(resource)
    Labrador::Session.clear_all
    new_user_session_path
  end

  def catch_errors
    begin
      yield
    rescue Exception => exception
      handle_runtime_error(exception)
    end
  end

  def render_json_error(error)
    render json: { error: error.to_s }
  end

  private

  def exports
    gon
  end

  def current_app
    find_application_from_url || Labrador::NullApp.new
  end

  def current_adapter
    current_app.find_adapter_by_name(params[:adapter])
  end

  def find_application_from_url
    if @applications
      @applications.select{|app| app.name == app_name_from_url }.first
      # @applications.select{|app| app.name.downcase == app_name_from_url }.first
    end
  end

  def find_applications
    begin
      Labrador::Session.clear_all
      current_user.database_connections.each do |db|
        db_params = db.attributes.except("created_at", "updated_at", "user_id", "id").symbolize_keys
        app = Labrador::App.new(db_params)
        Labrador::Session.add db_params
      end
      @applications = Labrador::App.find_all_from_path(apps_path) +
                      Labrador::App.find_all_from_sessions
      current_app.connect
      if current_app.errors.any?
        return render_adapter_error(current_app.errors.first)
      end
    rescue Exception => exception
      handle_runtime_error(exception)
    end
  end

  def apps_path
    if path_param
      File.expand_path("#{path_param}/../")
    elsif Labrador::App.supports_pow?
      Labrador::App::POW_PATH
    end
  end

  def path_param
    return unless params[:path].present?
    path = "#{params[:path]}"
    path += ".#{params[:format].to_s}" if params[:format]
    path = "/#{path}" if path[0] != '~'

    path
  end

  def app_name_from_url
    if request.subdomain.present?
      request.subdomain
    else
      path_param.to_s.split("/").last
    end
  end

  def authenticated?
    current_user
    # session[:authenticated]
  end

  # Handle redirecting to error page from an AdapterError
  #
  # adapter_error - The AdapterError generated from the current application
  #
  # Redirects to error_path with flash populated from error context
  def render_adapter_error(adapter_error)
    flash[:dump] = adapter_error.dump
    flash[:notice] = t('flash.notice.invalid_adapter',
      adapter: adapter_error.adapter,
      app: current_app.name
    )
    flash[:error] = adapter_error.message
    return redirect_to error_path
  end

  def handle_runtime_error(exception)
    current_app.disconnect
    if request.xhr?
      return render_json_error(exception)
    else
      flash[:dump] = exception.to_s
      return redirect_to error_path
    end
  end

  def http_authenticate
    # return if self.controller_name == 'sessions' && ['new', 'create'].include?(self.action_name)
    # return if self.controller_name == 'registrations' && ['new', 'create'].include?(self.action_name)
    # return if self.controller_name == 'password' && ['new', 'create'].include?(self.action_name)
    unless user_signed_in?
      redirect_to '/vi/bkdatabase'
    end
    # unless authenticated?
      # return redirect_to new_user_session_path
    # end

    # authenticate_or_request_with_http_basic do |username, password|
    # authenticated = (username == ENV['LABRADOR_USER'] && password == ENV['LABRADOR_PASS'])
    # session[:authenticated] = true if authenticated

    # authenticated
    # end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options(options={})
    { locale: I18n.locale }
  end

end
