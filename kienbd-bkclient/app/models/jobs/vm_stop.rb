class Jobs::VMStop
  @queue = :default

  def self.perform(instance)
    puts "waiting for stopping job #{instance["name"]}"
    state = Instance.updateState(instance["id"]).downcase
    if state == "stopping"
      Resque.enqueue_at(20.seconds.from_now, Jobs::VMStop, instance)
    elsif state == "stopped"
      puts "#{instance["name"]} stopped"
    end
  end

end
