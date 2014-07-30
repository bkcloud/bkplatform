require 'redis'
require 'redis/objects'
require 'resque'
require 'resque_scheduler'
require 'resque_scheduler/server'

Resque.redis =
  Rails.application.class.configure do
  server = config.database_configuration[ env ][ "redis" ][ "host" ].first rescue "127.0.0.1:6379"
  host, port = server.split(":")
  db_number = config.database_configuration[ env ][ "redis" ][ "db" ].first rescue 0
  Redis::Objects.redis = Redis.new(:host=>host, :port=>port, :db=>db_number)
  end

# Resque.schedule = YAML.load_file(Rails.root.join('config', 'resque_schedule.yml'))
