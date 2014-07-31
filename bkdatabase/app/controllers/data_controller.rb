class DataController < ApplicationController

  before_filter :find_applications
  around_filter :catch_errors, only: [:index, :create, :update, :destroy]

  def index
    items = database.find(collection, finder_params)
    render json: {
      primary_key: database.primary_key_for(collection),
      collection: collection,
      fields: database.fields_for(items),
      items: items
    }
  end

  def schema
    items = database.schema(collection)
    render json: {
      collection: collection,
      fields: database.fields_for(items),
      items: items
    }
  end

  def create
    database.create(collection, data)
    render json: { success: true }
  end

  def update
    database.update(collection, params[:id], data)
    render json: { success: true }
  end

  def destroy
    database.delete(collection, params[:id])
    render json: { success: true }
  end

  def collections
    render json: database.collections
  end

  def dropdb
    db = DatabaseConnection.find_by name: dbName
    database = current_app.find_adapter_by_name(db["adapter"]).database
    database.dropDB(dbName, db["username"])
    db.destroy
    Labrador::Session.clear_all
    current_user.database_connections.each do |db|
      db_params = db.attributes.except("created_at", "updated_at", "user_id", "id").symbolize_keys
      app = Labrador::App.new(db_params)
      Labrador::Session.add db_params
    end
    render json: { success: true }
  end

  def createtable
    db = DatabaseConnection.find_by name: params['dbName']
    current_app = @applications.select{|app| app.name.downcase == db[:name] }.first
    if !current_app.find_adapter_by_name(db["adapter"]).connect.nil?
      database = current_app.find_adapter_by_name(db["adapter"]).database
      database.collections
      params['columns'] = params['columns'].map { |key, value| value }
      str = ""
      for i in params['columns'] do
        str += "`#{i['field']}` " + i['type'] + "(#{i['length']}) " + i['attributes'] + " " + i['default'] + " " + i['null'] + " " + i['extra'] + ","
        if i['index'] == 'PRIMARY'
          str += "PRIMARY KEY (`#{i['field']}`),"
        elsif i['index'] == 'UNIQUE'
          str += "UNIQUE KEY (`#{i['field']}`),"
        elsif i['index'] == 'INDEX'
        end
      end
      query = "CREATE TABLE `#{params['name']}` (
      #{str[0..-2]}
      ) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;"
      e = database.createTable(query)
      if e.class.to_s == "Mysql::ServerError::ParseError"
        render json: { success: false, message: e.message}
      else
        render json: { success: true }
      end
    end
  end

  def droptable
    database.dropTable(tableName)
    render json: { success: true }
  end

  private

  def database
    current_adapter.database
  end

  def tableName
    params[:tableName]
  end

  def dbName
    params[:databaseName]
  end

  def finder_params
    params.slice :limit, :order_by, :direction, :conditions, :skip
  end

  def collection
    params[:collection]
  end

  def data
    params[:data].to_hash
  end
end
