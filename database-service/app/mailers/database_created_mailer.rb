class DatabaseCreatedMailer < ActionMailer::Base
  default from: "cs.bkloud@gmail.com"

  def registration_confirmation(user, dbc)
    @user = user
    @db = dbc
    mail :to => user['email'], :subject => "New Database Created"
  end

end
