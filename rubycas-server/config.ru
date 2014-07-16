require 'rubygems'
require 'bundler/setup'

ENV['CONFIG_FILE'] = "#{File.dirname(__FILE__)}/config.yml" 
ENV["APP_ROOT"] = File.expand_path(".")

$:.unshift "#{File.dirname(__FILE__)}/lib"
require "casserver"

use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger

run CASServer::Server.new
