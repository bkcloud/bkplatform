# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Bkclient::Application.initialize!
require 'casclient'
require 'casclient/frameworks/rails/filter'

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "http://bkcloud.net/cas"
  #:cas_base_url => "http://123.30.234.253"
)





