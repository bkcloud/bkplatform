class CSMailer < ActionMailer::Base
  default from: "cs.bkloud@gmail.com"

  def instance_approve_notifier(inst_id)
    @instance = Instance.find(inst_id)
    @inst_name = @instance.name
    @inst_id = inst_id
    @inst_hostname = @instance.hostname
    @inst_port = @instance.port
    @username = @instance.user.username
    @email = @instance.user.email
    mail(:to => @email, :subject => "Your Instance is now on AIR!!!!")
  end

end
