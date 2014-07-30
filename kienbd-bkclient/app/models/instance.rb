class Instance < ActiveRecord::Base

  belongs_to :user
  belongs_to :template
  belongs_to :service_offering
  belongs_to :disk_offering

  validates :name, presence: true, uniqueness: true
  validates :displayname, presence: true
  validates_format_of :displayname, :with => /\A[a-zA-Z0-9-]+\z/
  validates :service_offering_id, presence: true
  validates :template_id, presence: true
  #validate :has_template
  validate :has_service_offering
  validate :has_disk_offering

  def has_template
    unless template
      errors[:template_id] << 'Template does not exist'
    end
  end

  def has_service_offering
    unless service_offering
      errors[:service_offering_id] << 'Service Offering does not exist'
    end
  end

  def has_disk_offering
    unless (disk_offering_id == nil || disk_offering)
      errors[:disk_offering_id] << 'DiskOffering does not exist'
    end
  end

  scope :running, -> {where(state: 'running')}
  scope :starting, -> {where(state: 'starting')}
  scope :stopping, -> {where(state: 'stopping')}
  scope :stopped, -> {where(state: 'stopped')}
  scope :pending, -> {where(state: 'pending')}
  scope :waiting, -> {where(state: 'waiting')}


  def method_missing(method_name, *arguments, &block)
    if method_name.to_s =~ /is_(.*)\?/
      self.state.downcase == $1.downcase
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('is_') || super
  end



  class << self

    def isCreated(id)
      # check if VM is created or not
      instance = Instance.find_by id: id
      return instance.isCreated
    end

    def VNCToSPICEProtocol(id)
      instance = Instance.find_by id: id
      return instance.VNCToSPICEProtocol
    end

    def start(id)
      instance = Instance.find_by id: id
      return instance.start
    end

    def stop(id)
      instance = Instance.find_by id: id
      return instance.stop
    end

    def updateState(id)
      instance = Instance.find_by id: id
      return instance.updateState
    end

  end

  def isSPICE?
    return true if self.hostname && self.port
    return false
  end

  def VNCToSPICEProtocol

    return false if self.isCreated == false

    #check if VM is running or not
    if self.updateState.downcase != "running"
      return false
    end

    @hostname = Bkclient::Application.config.cloudstack[:ip]
    @username = Bkclient::Application.config.cloudstack[:vnc2spice_user]
    # @password = Bkclient::Application.config.cloudstack[:vnc2spice_passwd]
    @cmd = "sudo /scripts/call_change_vnc_to_spice.py #{self.instance_id}" #cmd to run script here
    # this command return
    # {"status"=>"OK", "message"=>["192.168.50.11", "5901"]} for success
    # {"status"=>"ERROR", "message"=>"error name"}

    begin
      res = {}
      Net::SSH.start(
        @hostname, @username,
        host_key: "ssh-rsa",
        keys: [ Rails.root.join('scripts','ssh-rsa-key').to_s ]
      ) do |ssh|
        res = ssh.exec!(@cmd)
      end
      # ssh = Net::SSH.start(@hostname, @username, :password => @password)
      # res = ssh.exec!(@cmd)
      # ssh.close
      # need to check res to ensure script work well
      # puts res
      res = JSON.parse(res)
      if res["status"] == "OK"
	#if res["message"][0] == "192.168.50.11"
	#  res["message"][0] = "202.191.58.54"
	#elsif res["message"][0] == "192.168.50.14"
	#  res["message"][0] = "202.191.58.56"
	#end

        self.update_attributes!(
          hostname: res["message"][0],
          port: res["message"][1]
        )
        # active spice web socket
        `#{Rails.root.join('scripts','websockify-daemon.sh').to_s} #{res["message"][0]}:#{res["message"][1]}-#{res["message"][1]}`
        return true
      else
        puts res["message"]
        return false
      end
    rescue
      puts "Unable to connect to #{@hostname} using #{@username}"
      return false
    end
  end

  # deploy new instance to cloud, return nil if there are any error
  def deploy
    if self.is_pending?
      zone_id = "c70a4033-3a72-4900-8aa3-8f1bee765d4b"
      args = { command: "deployVirtualMachine",
               serviceofferingid: self.service_offering.service_offering_id,
               templateid: self.template.template_id,
               zoneid: zone_id,
               name: self.name,
               displayname: self.displayname
      }
      if !self.disk_offering.nil?
        args.merge!(diskofferingid: self.disk_offering.disk_offering_id)
      end
      res = ApplicationController.helpers.postRequest(args)
      return false if res.nil?
      self.update_column(:job_created_id, res["deployvirtualmachineresponse"]["jobid"])
      self.update_column(:state,"approving")
      # need to check when job is completed to update instance_id
      # automatick switch to SPICE when created
      # Resque.enqueue(Jobs::VMDeploy, self)
      VMDeploy.perform_async(JSON.parse(self.to_json))
      return true
    end
    return false
  end

  # return state of instance, return nil if response error
  def updateState
    # state of VM can be: starting, running, stopping, stopped, pending(only in portal)
    return false if self.is_destroyed?
    res = ApplicationController.helpers.postRequest({ command: "listVirtualMachines", id: self.instance_id })
    return false if res.nil?
    self.update_attributes!(
      state: res["listvirtualmachinesresponse"]["virtualmachine"]["state"]
    )
    return self.state
  end

  def canStart?
    return false if !self.isCreated || !self.is_stopped?
    return true
  end

  def start
    self.updateState
    return false if !self.canStart?
    # if !self.is_running? && !self.is_starting? && !self.is_stopping? && !self.is_destroying? && !self.is_destroyed?
    res = ApplicationController.helpers.postRequest({ command: "startVirtualMachine", id: self.instance_id })
    return false if res.nil?
    self.update_attributes!(
      job_id: res["startvirtualmachineresponse"]["jobid"],
      state: "starting"
    )
    # Resque.enqueue_at(10.seconds.from_now, Jobs::VMStart, self) # do when starting finished
    VMStart.perform_in(10.seconds, JSON.parse(self.to_json))
    # end

    # need to add queue here to switch to SPICE automatically, because when VM stop,
    # protocol is set back to VNC,
    # need to change to SPICE
    # Resque.enqueue(Jobs::VNCToSPICE, self)

    return true
  end

  def canStop?
    return false if !self.isCreated || !self.is_running?
    return true
  end

  # forced = true to mark instance as stopped immediately
  def stop forced=false
    return false if self.updateState == false
    # return false if !self.canStop?
    if forced == true
      res = ApplicationController.helpers.postRequest({command: "stopVirtualMachine", id: self.instance_id, forced: "true"})
      return false if res.nil?
      self.update_attributes!(
        job_id: res["stopvirtualmachineresponse"]["jobid"],
        state: "stopped"
      )
      return true
    elsif self.canStop? == true
      res = ApplicationController.helpers.postRequest({command: "stopVirtualMachine", id: self.instance_id})
      return false if res.nil?
      self.update_attributes!(
        job_id: res["stopvirtualmachineresponse"]["jobid"],
        state: "stopping"
      )
      # Resque.enqueue_at(10.seconds.from_now, Jobs::VMStop, self) # update state to stopped
      VMStop.perform_in(10.seconds, JSON.parse(self.to_json))
      return true
    else
      return false
    end
  end

  def canDestroy?
    return false if self.is_destroying? || self.is_destroyed? || !self.isCreated
    return true
  end

  def destroy_vm
    return false if self.updateState == false
    return false if !self.canDestroy?
    res = ApplicationController.helpers.postRequest({
      command: "destroyVirtualMachine",
      id: self.instance_id
    })
    return false if res.nil?
    self.update_attributes!(
      job_id: res["destroyvirtualmachineresponse"]["jobid"],
      state: "Destroying"
    )
    VMDestroy.perform_in(10.seconds, JSON.parse(self.to_json))
    return true
  end

  def isCreated
    # check if VM is created or not
    # jobstatus: 0 for pending, 1 for complete, 2 for error
    return false if self.job_created_id.nil?
    if self.job_created_id.to_bool != true
      job = ApplicationController.helpers.postRequest({ command: "queryAsyncJobResult", jobid: self.job_created_id})
      return false if job.nil?
      if job["queryasyncjobresultresponse"]["jobstatus"].to_bool == false
        if job["queryasyncjobresultresponse"]["jobstatus"] != "0"
          self.update_attributes!(
            state: "Error" # unnable to create instance
          )
        end
        return false #job hasnt completed yet
      end
      # not verify the below instruction yet. just guess
      self.update_attributes!(
        instance_id: job["queryasyncjobresultresponse"]["jobresult"]["virtualmachine"]["id"],
        created_at: DateTime.iso8601(job["queryasyncjobresultresponse"]["jobresult"]["virtualmachine"]["created"]),
        state: job["queryasyncjobresultresponse"]["jobresult"]["virtualmachine"]["state"],
        job_created_id: "1"
      )
    end

    return false if self.is_destroying? || self.is_destroyed?
    self.updateState
    return false if self.is_destroying? || self.is_destroyed?
    return true
  end

end
