# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Labrador::Application.initialize!
require 'casclient'
require 'casclient/frameworks/rails/filter'

CASClient::Frameworks::Rails::Filter.configure(
  # :cas_base_url => "http://192.168.50.14/cas"
  :cas_base_url => "http://bkcloud.net/cas"
  #:cas_base_url => "http://202.191.58.55/cas"
)
