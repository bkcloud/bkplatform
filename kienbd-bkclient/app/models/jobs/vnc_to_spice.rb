class Jobs::VNCToSPICE
  @queue = :default

  def self.perform(instance)
    puts "trying to activate spice protocol #{instace["name"]}"
    if Instance.VNCToSPICEProtocol(instance["id"]) == false
      Resque.enqueue_at(1.minutes.from_now, Jobs::VNCTpSPICE, instace)
    else
      puts "#{instance["name"]} SPICE activated"
    end
  end

end
