require 'cql'
module Labrador
  class MongoDB
    extend Configuration
    include Store
    include ViewHelper
    
    attr_accessor :host, :port, :user, :database, :session, :connection

    DEFAULT_PORT = 9402

    def initialize(params = {})      
      @host     = params[:host]
      @port     = params[:port] || DEFAULT_PORT
      @database = params[:database]
      @user     = params[:user]
      password  = params[:password]
      #binding.pry
      @session = Cql::Client.connect(hosts: [host], :credentials => {:username => user, :password => password}, keyspace: database)
      #binding.pry
    end

    def collections
	names = []
      	session.execute(%Q{SELECT columnfamily_name FROM system.schema_columnfamilies WHERE keyspace_name = '#{database}'}).each{|row|names << row['columnfamily_name']}
	names
    end

    def find(collection_name, options = {})
      limit        = (options[:limit] || 50).to_i
      results = []
      #binding.pry
      session.execute(%Q{select * from #{collection_name} LIMIT #{limit}}).each{|row|results << row}
      results
      #binding.pry
    end

    def create(collection_name, data = {})
      primary_key_name = primary_key_for(collection_name)
      values = data.collect{|key, val| "'#{session.escape_string(val.to_s)}'" }.join(", ")
      fields = data.collect{|key, val| key.to_s }.join(", ")
      session.execute("
        INSERT INTO #{collection_name}
        (#{ fields })
        VALUES (#{ values })
      ")
    end

    def createTable(args)
      begin
        query = session.prepare(args)
        query.execute()
        return True
      rescue Exception => e
        return e
      end
    #binding.pry
    end

    def dropTable(tableName)
      query = session.prepare("DROP TABLE IF EXISTS #{tableName}")
      query.execute()
      #binding.pry
    end

    def dropDB(dbName, user)
      begin
        query = session.prepare("DROP KEYSPACE #{dbName}")
        query.execute()
        session.close
        #binding.pry
        client = Cql::Client.connect(hosts: [Labrador::Application.config.cassandra[:host]], :credentials => {:username => Labrador::Application.config.cassandra[:username], :password => Labrador::Application.config.cassandra[:password]})
        #binding.pry
        client.execute("DROP USER #{user}")
        client.close
        #binding.pry
      rescue

      end
    end

    def update(collection_name, id, data = {})
      primary_key_name = primary_key_for(collection_name)
      prepared_key_values = data.collect{|key, val| "#{key}=?" }.join(",")
      values = data.values
      values << id
      query = session.prepare("
        UPDATE #{collection_name}
        SET #{ prepared_key_values }
        WHERE #{primary_key_name}=?
      ")
      query.execute(*values)
    end

    def delete(collection_name, id)
      primary_key_name = primary_key_for(collection_name)
      query = session.prepare("DELETE FROM #{collection_name} WHERE #{primary_key_name}=?")
      query.execute(id)
    end

    def primary_key_for(collection_name)
      names = []
      session.execute(%Q{select key_aliases  from system.schema_columnfamilies where columnfamily_name = '#{collection_name}' ALLOW FILTERING}).each{|row|names << row['key_aliases']}
      result=names[0].to_s
      result.gsub!("[\"", "")
      result.gsub!("\"]", "")
      result
      #binding.pry
    end

    def connected?
      session.connected?
    end

    def close
      session.close
    end

    def id
      "mongodb"
    end

    def name
      I18n.t('adapters.mongodb.title')
    end

    def schema(collection)
      results = []
      session.execute(%Q{select column_name,component_index,type from system.schema_columns where columnfamily_name = '#{collection}'ALLOW FILTERING}).each{|row|results << row}
      results
    end

    def as_json(options = nil)
      {
        id: self.id,
        name: self.name
      }
    end
  end
end

module BSON
  class ObjectId
    def as_json(options = nil)
      to_s
    end
  end
end
