class Jobs::VMStart
  @queue = :default

  def self.perform(instance)
    puts "waiting for starting job #{instance["name"]}"
    state = Instance.updateState(instance["id"]).downcase
    if state == "starting"
      Resque.enqueue_at(20.seconds.from_now, Jobs::VMStart, instance)
    elsif state == "running"
      Instance.VNCToSPICEProtocol(instance["id"])
      puts "#{instance["name"]} started"
    end
  end

end
