class CSApproveMailer
  include Sidekiq::Worker

  def perform(instance)
    puts "waiting for signal of mailing job #{instance["name"]}"
    CSMailer.instance_approve_notifier(instance["id"]).deliver
    puts "Mail for #{instance["name"]} sent"
  end

end
