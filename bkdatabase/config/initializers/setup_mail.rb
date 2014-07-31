ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :user_name => 'cs.bkloud@gmail.com',
  :password => 'bkloud@123',
  :authentication => 'plain',
  :enable_starttls_auto => true }

ActionMailer::Base.default_url_options[:host] = "0.0.0.0:3000"
