class DatabaseConnectionsController < ApplicationController
  include ApplicationHelper
  require Rails.root.join("lib","labrador.rb")

  before_filter :find_applications, only: [:new]
  around_filter :catch_errors, only: [:create, :destroy]

  def new
  end

  def create
    if params[:database_connection][:adapter] == "mysql"
	params[:database_connection][:username] = SecureRandom.base64(9)
	params[:database_connection][:password] = SecureRandom.base64(18)
	params[:database_connection][:host] = Labrador::Application.config.mysqlcluster[:host]
	params[:database_connection][:name] = params[:database_connection][:database]
	@dbc = current_user.database_connections.new(database_connection_params.permit(:user_id, :adapter, :name, :host, :database, :username, :password, :socket))
	db = Mysql.connect(
	Labrador::Application.config.mysqlcluster[:host],
	Labrador::Application.config.mysqlcluster[:username],
	Labrador::Application.config.mysqlcluster[:password]
	)
	# check o day
	db.query("CREATE DATABASE #{database_connection_params[:name]}")
	db.query("GRANT ALL PRIVILEGES ON #{database_connection_params[:name]}.* to '#{@dbc[:username]}'@localhost IDENTIFIED BY '#{@dbc[:password]}'")
	db.query("GRANT ALL PRIVILEGES ON #{database_connection_params[:name]}.* to '#{@dbc[:username]}'@'%' IDENTIFIED BY '#{@dbc[:password]}'")
	if @dbc.save
	app = Labrador::App.new(database_connection_params)
	Labrador::Session.add database_connection_params
	@user = current_user
	# DatabaseCreatedMailer.registration_confirmation(@user, @dbc).deliver
	redirect_to app_url(app)
	else
	render 'new'
	end
	# Labrador::Session.add database_params
	# redirect_to app_url(app)
    else
	range = [*'a'..'z', *'A'..'Z']
    	params[:database_connection][:username] = Array.new(9){range.sample}.join
    	params[:database_connection][:password] = SecureRandom.base64(18)
    	params[:database_connection][:host] = Labrador::Application.config.cassandra[:host]
    	params[:database_connection][:name] = params[:database_connection][:database]
    	@dbc = current_user.database_connections.new(database_connection_params.permit(:user_id, :adapter, :name, :host, :database, :username, :password, :socket))
    	client = Cql::Client.connect(hosts: [params[:database_connection][:host]], :credentials => {:username => Labrador::Application.config.cassandra[:username], :password => Labrador::Application.config.cassandra[:password]})
    	client.execute(%Q{CREATE KEYSPACE #{database_connection_params[:name]} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 }})
    	client.execute(%Q{CREATE USER #{@dbc[:username]} WITH PASSWORD '#{@dbc[:password]}'})
    	client.execute(%Q{GRANT ALL ON KEYSPACE #{database_connection_params[:name]} TO #{@dbc[:username]}})
    	client.close
    
    	if @dbc.save
      		app = Labrador::App.new(database_connection_params)
      		Labrador::Session.add database_connection_params
      		@user = current_user
      		DatabaseCreatedMailer.registration_confirmation(@user, @dbc).deliver
      		redirect_to app_url(app)
    	else
      		render 'new'
    	end
    end
  end

  def destroy
    @db = DatabaseConnection.find(params.require(:id))
    @db.destroy
    # Labrador::Databases.clear_all
    redirect_to root_url(subdomain: false)
  end


  private

  def database_connection_params
    params[:database_connection] ||= {}
    params[:database_connection].each{|key, value| session[key] = nil if value.blank? }
    params[:database_connection]
  end

  def grant_control

  end

end
