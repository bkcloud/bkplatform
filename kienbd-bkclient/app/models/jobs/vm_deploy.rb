class Jobs::VMDeploy
  @queue = :default

  def self.perform(instance)
    puts "waiting for deploying #{instance["name"]}"
    if Instance.isCreated(instance["id"]) == false && instance["state"] != "error"
      Resque.enqueue_at(1.minutes.from_now, Jobs::VMDeploy, instance)
    else # do first reboot to active internet connection
      Instance.stop(instance["id"])
      Resque.enqueue(Jobs::VMFirstReboot, instance)
    end
  end

end
