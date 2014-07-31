class VMStart
  include Sidekiq::Worker

  def perform(instance)
    puts "waiting for starting job #{instance["name"]}"
    state = Instance.updateState(instance["id"])
    if state == false || state.downcase == "starting"
      # Resque.enqueue_at(20.seconds.from_now, Jobs::VMStart, instance)
      VMStart.perform_in(20.seconds, instance)
    elsif state.downcase == "running"
      if Instance.VNCToSPICEProtocol(instance["id"])
        puts "#{instance["name"]} started in SPICE"
      else
        puts "#{instance["name"]} started, but not in SPICE"
      end
    end
  end

end
