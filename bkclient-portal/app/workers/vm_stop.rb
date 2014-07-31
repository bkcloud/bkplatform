class VMStop
  include Sidekiq::Worker

  def perform(instance)
    puts "waiting for stopping #{instance["name"]}"
    state = Instance.updateState(instance["id"])
    if state == false || state.downcase == "stopping"
      # Resque.enqueue_at(20.seconds.from_now, Jobs::VMStop, instance)
      VMStop.perform_in(20.seconds, instance)
    elsif state.downcase == "stopped"
      puts "#{instance["name"]} stopped"
    end
  end

end
