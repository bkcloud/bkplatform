class VMFirstReboot
  include Sidekiq::Worker

  def perform(instance)
    # state = Instance.updateState(instance["id"]).downcase
    puts "#{instance["name"]} first booting ..."
    instance = JSON.parse(Instance.find(instance["id"]).to_json)
    if instance["state"].downcase == "stopped"
      Instance.start(instance["id"])
      # Resque.enqueue_at(30.seconds.from_now, Jobs::VMFirstReboot, instance)
      VMFirstReboot.perform_in(30.seconds, instance)
    elsif instance["state"].downcase == "stopping" || instance["state"].downcase == "starting"
      # Resque.enqueue_at(30.seconds.from_now, Jobs::VMFirstReboot, instance)
      VMFirstReboot.perform_in(30.seconds, instance)
    elsif instance["state"].downcase == "running" && instance["hostname"].blank? == false
      # Resque.enqueue(Jobs::CSApproveMailer,instance)
      CSApproveMailer.perform_async(instance)
      puts "#{instance["name"]} deployed"
    end
  end

end
