class VMDeploy
  include Sidekiq::Worker

  def perform(instance)
    puts "waiting for deploying #{instance["name"]}"
    if Instance.isCreated(instance["id"]) == false && instance["state"] != "error"
      # Resque.enqueue_at(1.minutes.from_now, Jobs::VMDeploy, instance)
      VMDeploy.perform_in(1.minutes, instance)
    else # do first reboot to active internet connection
      if Instance.VNCToSPICEProtocol(instance["id"])
        puts "#{instance["name"]} started in SPICE"
      else
        puts "#{instance["name"]} started, but not in SPICE"
      end
      # Instance.stop(instance["id"])
      # Resque.enqueue(Jobs::VMFirstReboot, instance)
      # VMFirstReboot.perform_async(instance)
    end
  end

end
