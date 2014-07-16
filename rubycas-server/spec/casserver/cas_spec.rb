require 'spec_helper'

module CASServer; end
require 'casserver/cas'
require 'nokogiri'
require 'cgi'

describe CASServer::CAS do
  before do
    load_server("default_config")
    @klass = Class.new {
      include CASServer::CAS
    }
    @client_hostname = 'myhost.test'
    @host = @klass.new
    @host.instance_variable_set(:@env, {
      'REMOTE_HOST' => @client_hostname
    })
  end

  describe "#generate_login_ticket" do
    before do
      @lt = @host.generate_login_ticket
    end

    it "should return a login ticket" do
      @lt.class.should == CASServer::Model::LoginTicket
    end

    it "should set the client_hostname" do
      @lt.client_hostname.should == @client_hostname
    end

    it "should set the ticket string" do
      @lt.ticket.should_not be_nil
    end

    it "SHOULD set the ticket string starting with 'LT'" do
      @lt.ticket.should match /^LT/
    end

    it "should not mark the ticket as consumed" do
      @lt.consumed.should be_nil
    end
  end

  describe "#generate_ticket_granting_ticket(username, extra_attributes = {})" do
    before do
      @username = 'myuser'
      @tgt = @host.generate_ticket_granting_ticket(@username)
    end

    it "should return a TicketGrantingTicket" do
      @tgt.class.should == CASServer::Model::TicketGrantingTicket
    end

    it "should set the tgt's ticket string" do
      @tgt.ticket.should_not be_nil
    end

    it "should generate a ticket string starting with 'TGC'" do
      @tgt.ticket.should match /^TGC/
    end

    it "should set the tgt's username string" do
      @tgt.username.should == @username
    end

    it "should set the tgt's client_hostname" do
      @tgt.client_hostname.should == @client_hostname
    end
  end

  describe "#generate_service_ticket(service, username, tgt)" do
    before do
      @username = 'testuser'
      @service = 'myservice.test'
      @tgt = double(CASServer::Model::TicketGrantingTicket)
      @tgt.stub(:id => rand(10000))
      @st = @host.generate_service_ticket(@service, @username, @tgt)
    end

    it "should return a ServiceTicket" do
      @st.class.should == CASServer::Model::ServiceTicket
    end

    it "should not include the service identifer in the ticket string" do
      @st.ticket.should_not match /#{@service}/
    end

    it "should not mark the ST as consumed" do
      @st.consumed.should be_nil
    end

    it "MUST generate a ticket that starts with 'ST-'" do
      @st.ticket.should match /^ST-/
    end

    it "should assoicate the ST with the supplied TGT" do
      @st.granted_by_tgt_id.should == @tgt.id
    end
  end

  describe "#generate_proxy_ticket(target_service, pgt)" do
    before do
      @target_service = 'remoteservice.test'
      @st = CASServer::Model::ServiceTicket.new({
        :username => 'joe',
        :granted_by_tgt_id => rand(10000)
      })
      @pgt = double(CASServer::Model::ProxyGrantingTicket)
      @pgt.stub({
        :id => rand(10000),
        :service_ticket => @st,
        :ticket => 'some ticket'
      })
      @pt = @host.generate_proxy_ticket(@target_service, @pgt)
    end

    it "should return a ProxyGrantingTicket" do
      @pt.class.should == CASServer::Model::ProxyTicket
    end

    it "should not consume the generated ticket" do
      @pt.consumed.should be_nil
    end

    it "should start the ticket string with PT-" do
      @pt.ticket.should match /^PT-/
    end
  end

  describe "#send_logout_notification_for_service_ticket(st)" do
    it "should send valid single sign out XML to the service URL" do
      service_stub = stub_request(:post, 'http://example.com')
      st = CASServer::Model::ServiceTicket.new(
        :ticket => 'ST-0123456789ABCDEFGHIJKLMNOPQRS',
        :service => 'http://example.com'
      )
      @host.send_logout_notification_for_service_ticket(st)

      a_request(:post, 'example.com').with{ |req|
        xml = CGI.parse(req.body)['logoutRequest'].first
        Nokogiri::XML(xml).at_xpath('//samlp:SessionIndex').text.strip == st.ticket
      }.should have_been_made
    end
  end
end
