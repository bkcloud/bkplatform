class Jobs::VMFirstReboot
  @queue = :default

  def self.perform(instance)
    # state = Instance.updateState(instance["id"]).downcase
    puts "#{instance["name"]} first booting ..."
    instance = Instance.find(instance["id"])
    if instance["state"].downcase == "stopped"
      Instance.start(instance["id"])
      Resque.enqueue_at(30.seconds.from_now, Jobs::VMFirstReboot, instance)
    elsif instance["state"].downcase == "stopping" || instance["state"].downcase == "starting"
      Resque.enqueue_at(30.seconds.from_now, Jobs::VMFirstReboot, instance)
    elsif instance["state"].downcase == "running" && instance["hostname"].blank? == false
      Resque.enqueue(Jobs::CSApproveMailer,instance)
      puts "#{instance["name"]} deployed"
    end
  end

end
