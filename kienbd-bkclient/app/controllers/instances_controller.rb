class InstancesController < ApplicationController
  before_filter :is_admin ,only: [:approve]
  before_filter :is_user, only: [:new, :show, :viewSpiceWebSock]
  #before_filter :authenticate_user!, except: [:approve]

  #before_filter CASClient::Frameworks::Rails::Filter,:except => [:approve]
  #before_filter CASClient::Frameworks::Rails::GatewayFilter,:only => [:approve]
  before_filter :setup_cas_user,:except => [:approve]


  # view virtual machine in SPICE via websocket controller
  # GET /instances/:id/viewSpiceWebSock
  def viewSpiceWebSock
    @instance = Instance.find(params[:id])
    if @instance.isSPICE?
      cmd = "ps -ef|grep -Eo 'websockify.py.[0-9]{3,}.#{@instance.hostname}:#{@instance.port}'"
      res = `#{cmd}`
      res =~ /websockify.py.([0-9]{3,})./
      port = $1
      if port.nil?
        `#{Rails.root.join('scripts','websockify-daemon.sh').to_s} #{@instance.hostname}:#{@instance.port}-#{@instance.port}`
          res = `#{cmd}`
          res =~ /websockify.py.([0-9]{3,})./
          port = $1
      end
    end
    if port
      @host = request.host
      @port = port
      respond_to do |format|
        format.html
        format.js
      end
    else
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  # controller: permit instance to be deployed
  # GET /instances/:id/approve
  def approve
    @instance = Instance.find(params[:id])
    if @instance.deploy
      respond_to do |format|
        format.html
        format.js
        format.json
      end
    else
      respond_to do |format|
        format.html
        format.js
        format.json
      end
    end

  end

  # Controller to request all necessary options to create new VM
  # GET /instances/new
  def new
    @templates = Template.all
    @diskOfferings = DiskOffering.all.sort_by { |e| e.disksize }
    @serviceOfferings = ServiceOffering.all
    respond_to do |format|
      format.html
      format.js
      format.json
    end
  end

  # create new instance record (is not deployed yet)
  # POST /instances
  def create
    name = current_user.username + "-" + params["instance"]["displayname"]
    @instance = Instance.new(params.require(:instance).merge(:user_id => current_user.id, :name => name).permit(:name, :displayname, :template_id, :disk_offering_id, :service_offering_id, :user_id))
    if @instance.save
      redirect_to confirmation_path
    else
      @templates = Template.all
      @diskOfferings = DiskOffering.all.sort_by { |e| e.disksize }
      @serviceOfferings = ServiceOffering.all
      render 'new'
    end
  end

  # list an instance information
  # GET /instances/:id
  def show
    @instance = Instance.find(params.require(:id))
    @instance.updateState if @instance.isCreated
    respond_to do |format|
      format.html
      format.js
      format.json
    end
  end

  # start an instance
  # GET /instances/:id/start
  def start
    @instance = Instance.find(params.require(:id))
    if @instance.start
      respond_to do |format|
        # format.html
        format.js
        # format.json
      end
    else
      respond_to do |format|
        format.js { render action: "start_fail" }
      end
    end
  end

  # stop an instance
  # GET /instances/:id/shutdown
  def shutdown
    @instance = Instance.find(params.require(:id))
    if @instance.stop
      respond_to do |format|
        # format.html
        format.js
        # format.json
      end
    else
      respond_to do |format|
        # format.html
        format.js { render action: "shutdown_fail" }
        # format.json
      end
    end
  end

  # destroy an instance
  # GET /instances/:id/remove
  def remove
    @instance = Instance.find(params.require(:id))
    if @instance.destroy_vm
      respond_to do |format|
        format.html {
	    render nothing: true
	    redirect_to @instance
	}
        format.js
        format.json
      end
    else
      respond_to do |format|
        format.html {
	    render nothing: true
	    redirect_to @instance
	}
        format.js
        format.json
      end
    end
  end

  def send_mail
    instance = Instance.find(params[:id])
    CSApproveMailer.perform_async(JSON.parse(instance.to_json))
    # Resque.enqueue(Jobs::CSApproveMailer,instance)

    respond_to do |format|
      format.js
    end
  end

  private
  def is_admin
    if !admin_signed_in?
      redirect_to root_path
    end
  end

  def is_user
    if !user_signed_in?
      redirect_to root_path
    end
  end
end
