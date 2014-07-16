class PagesController < ApplicationController

  layout 'bare', only: [:unauthorized, :error]

  before_filter :find_applications, except: [:error, :unauthorized, :installation]

  def home
    puts "aloha"
    exports.app = current_app.as_json
    exports.databases = current_app.adapters.collect(&:database).as_json
    redirect_to new_database_connection_url(subdomain: false) unless current_app.connected?
  end

  def unauthorized
  end

  def error
    Labrador::Session.clear_all
    if current_user
      current_user.database_connections.each do |db|
        db_params = db.attributes.except("created_at", "updated_at", "user_id", "id").symbolize_keys
        app = Labrador::App.new(db_params)
        Labrador::Session.add db_params
      end
    end
  end

  def installation

  end

end
