class HomeController < ApplicationController
  before_filter :is_admin ,only: [:sync,:admin_page]
  #before_filter :authenticate_user!, except: [:welcome, :index, :admin_page, :sync]

  before_filter CASClient::Frameworks::Rails::Filter,:except => [:welcome,:admin_page,:sync,:index,:logout,:confirmation]
  #before_filter CASClient::Frameworks::Rails::Filter,:except => [:welcome,:admin_page,:sync,:index]
  before_filter CASClient::Frameworks::Rails::GatewayFilter,:only => [:welcome,:sync,:index]
  before_filter :setup_cas_user
  # before_filter :setup_cas_user,:except => [:welcome, :admin_page, :sync, :index,:confirmation]

  def logout
    # optionally do some local cleanup here
    sign_out(current_user) unless current_user.nil?
    return_path = APP_CONFIG["url"]
    CASClient::Frameworks::Rails::Filter.logout(self,return_path) 
  end

  # welcome for virtual desktop service
  def welcome
    @return_path = APP_CONFIG["url"]
  end

  # show 3 services
  def index
    I18n.locale= :vi
  end

  # confirmation after user create instance
  def comfirmation
  end

  # synchronize the lastest options for virtual machine registratons
  # GET /sync
  def sync
    begin
      Template.sync
      DiskOffering.sync
      ServiceOffering.sync
      respond_to do |format|
        format.html {
          flash[:success] = "Synchronization Finished !"
          redirect_to admin_page_path
        }
      end
    rescue
      respond_to do |format|
        format.html {
          flash[:failed] = "Synchronization Failed !"
          redirect_to admin_page_path
        }
      end
    end
  end

  # admin page controller
  def admin_page
    @instances = Instance.all.order("created_at ASC")
  end


  private
  def is_admin
    if !admin_signed_in?
      redirect_to root_path
    end
  end

end
