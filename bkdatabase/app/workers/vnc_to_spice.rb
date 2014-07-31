class VNCToSPICE
  include Sidekiq::Worker

  def perform(instance)
    puts "trying to activate spice protocol #{instace["name"]}"
    if Instance.VNCToSPICEProtocol(instance["id"]) == false
      # Resque.enqueue_at(1.minutes.from_now, Jobs::VNCToSPICE, instace)
      VNCToSPICE.perform_in(30.seconds, instance)
    else
      puts "#{instance["name"]} SPICE activated"
    end
  end

end
