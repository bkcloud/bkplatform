require 'casserver/utils'
require 'casserver/cas'
require 'casserver/base'
require 'casserver/authenticators/base'

module CASServer
  class Server < CASServer::Base
    if ENV['CONFIG_FILE']
      CONFIG_FILE = ENV['CONFIG_FILE']
    elsif !(c_file = File.dirname(__FILE__) + "/../../config.yml").nil? && File.exist?(c_file)
      CONFIG_FILE = c_file
    else
      CONFIG_FILE = "/etc/rubycas-server/config.yml"
    end

    include CASServer::CAS # CAS protocol helpers

    # Use :public_folder for Sinatra >= 1.3, and :public for older versions.
    def self.use_public_folder?
      Sinatra.const_defined?("VERSION") && Gem::Version.new(Sinatra::VERSION) >= Gem::Version.new("1.3.0")
    end

    set :app_file, __FILE__
    set( use_public_folder? ? :public_folder : :public, # Workaround for differences in Sinatra versions.
         Proc.new { settings.config[:public_dir] || File.join(root, "..", "..", "public") } )

    config = HashWithIndifferentAccess.new(
      :maximum_unused_login_ticket_lifetime => 5.minutes,
      :maximum_unused_service_ticket_lifetime => 5.minutes, # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
      :maximum_session_lifetime => 2.days, # all tickets are deleted after this period of time
      :log => {:file => 'casserver.log', :level => 'DEBUG'},
      :uri_path => ""
    )
    set :config, config

    def self.uri_path
      config[:uri_path]
    end

    # Strip the config.uri_path from the request.path_info...
    # FIXME: do we really need to override all of Sinatra's #static! to make this happen?
    def static!
      # Workaround for differences in Sinatra versions.
      public_dir = Server.use_public_folder? ? settings.public_folder : settings.public
      return if public_dir.nil?
      public_dir = File.expand_path(public_dir)

      path = File.expand_path(public_dir + unescape(request.path_info.gsub(/^#{settings.config[:uri_path]}/,'')))
      return if path[0, public_dir.length] != public_dir
      return unless File.file?(path)

      env['sinatra.static_file'] = path
      send_file path, :disposition => nil
    end

    def self.run!(options={})
      set options

      handler      = detect_rack_handler
      handler_name = handler.name.gsub(/.*::/, '')

      puts "== RubyCAS-Server is starting up " +
        "on port #{config[:port] || port} for #{environment} with backup from #{handler_name}" unless handler_name =~/cgi/i

      begin
        opts = handler_options
      rescue Exception => e
        print_cli_message e, :error
        raise e
      end

      handler.run self, opts do |server|
        [:INT, :TERM].each { |sig| trap(sig) { quit!(server, handler_name) } }
        set :running, true
      end
    rescue Errno::EADDRINUSE => e
      puts "== Something is already running on port #{port}!"
    end

    def self.quit!(server, handler_name)
      ## Use thins' hard #stop! if available, otherwise just #stop
      server.respond_to?(:stop!) ? server.stop! : server.stop
      puts "\n== RubyCAS-Server is shutting down" unless handler_name =~/cgi/i
    end

    def self.print_cli_message(msg, type = :info)
      if respond_to?(:config) && config && config[:quiet]
        return
      end

      if type == :error
        io = $stderr
        prefix = "!!! "
      else
        io = $stdout
        prefix = ">>> "
      end

      io.puts
      io.puts "#{prefix}#{msg}"
      io.puts
    end

    def self.load_config_file(config_file)
      begin
        config_file = File.open(config_file)
      rescue Errno::ENOENT => e

        print_cli_message "Config file #{config_file} does not exist!", :error
        print_cli_message "Would you like the default config file copied to #{config_file.inspect}? [y/N]"
        if gets.strip.downcase == 'y'
          require 'fileutils'
          default_config = File.dirname(__FILE__) + '/../../config/config.example.yml'

          if !File.exists?(File.dirname(config_file))
            print_cli_message "Creating config directory..."
            FileUtils.mkdir_p(File.dirname(config_file), :verbose => true)
          end

          print_cli_message "Copying #{default_config.inspect} to #{config_file.inspect}..."
          FileUtils.cp(default_config, config_file, :verbose => true)
          print_cli_message "The default config has been copied. You should now edit it and try starting again."
          exit
        else
          print_cli_message "Cannot start RubyCAS-Server without a valid config file.", :error
          raise e
        end
      rescue Errno::EACCES => e
        print_cli_message "Config file #{config_file.inspect} is not readable (permission denied)!", :error
        raise e
      rescue => e
        print_cli_message "Config file #{config_file.inspect} could not be read!", :error
        raise e
      end

      config.merge! HashWithIndifferentAccess.new(YAML.load(config_file))
      set :server, config[:server] || 'webrick'
    end

    def self.handler_options
      handler_options = {
        :Host => bind || config[:bind_address],
        :Port => config[:port] || 443
      }

      handler_options.merge(handler_ssl_options).to_hash.symbolize_keys!
    end

    def self.handler_ssl_options
      return {} unless config[:ssl_cert]

      cert_path = config[:ssl_cert]
      key_path = config[:ssl_key] || config[:ssl_cert]

      unless cert_path.nil? && key_path.nil?
        raise "The ssl_cert and ssl_key options cannot be used with mongrel. You will have to run your " +
          " server behind a reverse proxy if you want SSL under mongrel." if
            config[:server] == 'mongrel'

        raise "The specified certificate file #{cert_path.inspect} does not exist or is not readable. " +
          " Your 'ssl_cert' configuration setting must be a path to a valid " +
          " ssl certificate." unless
            File.exists? cert_path

        raise "The specified key file #{key_path.inspect} does not exist or is not readable. " +
          " Your 'ssl_key' configuration setting must be a path to a valid " +
          " ssl private key." unless
            File.exists? key_path

        require 'openssl'
        require 'webrick/https'

        cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
        key = OpenSSL::PKey::RSA.new(File.read(key_path))

        {
          :SSLEnable        => true,
          :SSLVerifyClient  => ::OpenSSL::SSL::VERIFY_NONE,
          :SSLCertificate   => cert,
          :SSLPrivateKey    => key
        }
      end
    end

    def self.init_authenticators!
      auth = []

      if config[:authenticator].nil?
        print_cli_message "No authenticators have been configured. Please double-check your config file (#{CONFIG_FILE.inspect}).", :error
        exit 1
      end

      begin
        # attempt to instantiate the authenticator
        config[:authenticator] = [config[:authenticator]] unless config[:authenticator].instance_of? Array
        config[:authenticator].each { |authenticator| auth << authenticator[:class].constantize}
      rescue NameError
        if config[:authenticator].instance_of? Array
          config[:authenticator].each do |authenticator|
            if !authenticator[:source].nil?
              # config.yml explicitly names source file
              require authenticator[:source]
            else
              # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
              auth_rb = authenticator[:class].underscore.gsub('cas_server/', '')
              require 'casserver/'+auth_rb
            end
            auth << authenticator[:class].constantize
          end
        else
          if config[:authenticator][:source]
            # config.yml explicitly names source file
            require config[:authenticator][:source]
          else
            # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
            auth_rb = config[:authenticator][:class].underscore.gsub('cas_server/', '')
            require 'casserver/'+auth_rb
          end

          auth << config[:authenticator][:class].constantize
          config[:authenticator] = [config[:authenticator]]
        end
      end

      auth.zip(config[:authenticator]).each_with_index{ |auth_conf, index|
        authenticator, conf = auth_conf
        $LOG.debug "About to setup #{authenticator} with #{conf.inspect}..."
        authenticator.setup(conf.merge('auth_index' => index)) if authenticator.respond_to?(:setup)
        $LOG.debug "Done setting up #{authenticator}."
      }

      set :auth, auth
    end

    def self.init_logger!
      if config[:log]
        if $LOG && config[:log][:file]
          print_cli_message "Redirecting RubyCAS-Server log to #{config[:log][:file]}"
          #$LOG.close
          $LOG = Logger.new(config[:log][:file])
        end
        $LOG.level = Logger.const_get(config[:log][:level]) if config[:log][:level]
      end

      if config[:db_log]
        if $LOG && config[:db_log][:file]
          $LOG.debug "Redirecting ActiveRecord log to #{config[:log][:file]}"
          #$LOG.close
          ActiveRecord::Base.logger = Logger.new(config[:db_log][:file])
        end
        ActiveRecord::Base.logger.level = Logger.const_get(config[:db_log][:level]) if config[:db_log][:level]
      end
    end

    def self.init_database!

      unless config[:disable_auto_migrations]
        ActiveRecord::Base.establish_connection(config[:database])
        print_cli_message "Running migrations to make sure your database schema is up to date..."
        prev_db_log = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = Logger.new(STDOUT)
        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(File.dirname(__FILE__) + "/../../db/migrate")
        ActiveRecord::Base.logger = prev_db_log
        print_cli_message "Your database is now up to date."
      end

      ActiveRecord::Base.establish_connection(config[:database])
    end

    configure do
      load_config_file(CONFIG_FILE)
      init_logger!
      init_database!
      init_authenticators!
    end

    before do
      content_type :html, 'charset' => 'utf-8'
      @theme = settings.config[:theme]
      @organization = settings.config[:organization]
      @uri_path = settings.config[:uri_path]
      @infoline = settings.config[:infoline]
      @custom_views = settings.config[:custom_views]
      @template_engine = settings.config[:template_engine] || :erb
      if @template_engine != :erb
        require @template_engine
        @template_engine = @template_engine.to_sym
      end
    end

    # The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
    # under http://www.ja-sig.org/products/cas/overview/protocol/index.html

    # 2.1 :: Login

    # 2.1.1
    get "#{uri_path}/login" do
      CASServer::Utils::log_controller_action(self.class, params)

      # make sure there's no caching
      headers['Pragma'] = 'no-cache'
      headers['Cache-Control'] = 'no-store'
      headers['Expires'] = (Time.now - 1.year).rfc2822

      # optional params
      @service = clean_service_url(params['service'])
      @renew = params['renew']
      @gateway = params['gateway'] == 'true' || params['gateway'] == '1'

      if tgc = request.cookies['tgt']
        tgt, tgt_error = validate_ticket_granting_ticket(tgc)
      end

      if tgt and !tgt_error
        @authenticated = true
        @authenticated_username = tgt.username
        @message = {:type => 'notice',
          :message => t.notice.logged_in_as(tgt.username)}
      elsif tgt_error
        $LOG.debug("Ticket granting cookie could not be validated: #{tgt_error}")
      elsif !tgt
        $LOG.debug("No ticket granting ticket detected.")
      end

      if params['redirection_loop_intercepted']
        @message = {:type => 'mistake',
          :message => t.error.unable_to_authenticate}
      end

      begin
        if @service
          if @renew
            $LOG.info("Authentication renew explicitly requested. Proceeding with CAS login for service #{@service.inspect}.")
          elsif tgt && !tgt_error
            $LOG.debug("Valid ticket granting ticket detected.")
            st = generate_service_ticket(@service, tgt.username, tgt)
            service_with_ticket = service_uri_with_ticket(@service, st)
            $LOG.info("User '#{tgt.username}' authenticated based on ticket granting cookie. Redirecting to service '#{@service}'.")
            redirect service_with_ticket, 303 # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
          elsif @gateway
            $LOG.info("Redirecting unauthenticated gateway request to service '#{@service}'.")
            redirect @service, 303
          else
            $LOG.info("Proceeding with CAS login for service #{@service.inspect}.")
          end
        elsif @gateway
            $LOG.error("This is a gateway request but no service parameter was given!")
            @message = {:type => 'mistake',
              :message => t.error.no_service_parameter_given}
        else
          $LOG.info("Proceeding with CAS login without a target service.")
        end
      rescue URI::InvalidURIError
        $LOG.error("The service '#{@service}' is not a valid URI!")
        @message = {:type => 'mistake',
          :message => t.error.invalid_target_service}
      end

      lt = generate_login_ticket

      $LOG.debug("Rendering login form with lt: #{lt}, service: #{@service}, renew: #{@renew}, gateway: #{@gateway}")

      @lt = lt.ticket

      #$LOG.debug(env)

      # If the 'onlyLoginForm' parameter is specified, we will only return the
      # login form part of the page. This is useful for when you want to
      # embed the login form in some external page (as an IFRAME, or otherwise).
      # The optional 'submitToURI' parameter can be given to explicitly set the
      # action for the form, otherwise the server will try to guess this for you.
      if params.has_key? 'onlyLoginForm'
        if @env['HTTP_HOST']
          guessed_login_uri = "http#{@env['HTTPS'] && @env['HTTPS'] == 'on' ? 's' : ''}://#{@env['REQUEST_URI']}#{self / '/login'}"
        else
          guessed_login_uri = nil
        end

        @form_action = params['submitToURI'] || guessed_login_uri

        if @form_action
          render :login_form
        else
          status 500
          render t.error.invalid_submit_to_uri
        end
      else
        render @template_engine, :login
      end
    end


    # 2.2
    post "#{uri_path}/login" do
      Utils::log_controller_action(self.class, params)

      # 2.2.1 (optional)
      @service = clean_service_url(params['service'])

      # 2.2.2 (required)
      @username = params['username']
      @password = params['password']
      @lt = params['lt']

      # Remove leading and trailing widespace from username.
      @username.strip! if @username

      if @username && settings.config[:downcase_username]
        $LOG.debug("Converting username #{@username.inspect} to lowercase because 'downcase_username' option is enabled.")
        @username.downcase!
      end

      if error = validate_login_ticket(@lt)
        @message = {:type => 'mistake', :message => error}
        # generate another login ticket to allow for re-submitting the form
        @lt = generate_login_ticket.ticket
        status 500
        return render @template_engine, :login
      end

      # generate another login ticket to allow for re-submitting the form after a post
      @lt = generate_login_ticket.ticket

      $LOG.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{settings.auth.inspect}")

      credentials_are_valid = false
      extra_attributes = {}
      successful_authenticator = nil
      begin
        auth_index = 0
        settings.auth.each do |auth_class|
          auth = auth_class.new

          auth_config = settings.config[:authenticator][auth_index]
          # pass the authenticator index to the configuration hash in case the authenticator needs to know
          # it splace in the authenticator queue
          auth.configure(auth_config.merge('auth_index' => auth_index))

          credentials_are_valid = auth.validate(
            :username => @username,
            :password => @password,
            :service => @service,
            :request => @env
          )
          if credentials_are_valid
            @authenticated = true
            @authenticated_username = @username
            extra_attributes.merge!(auth.extra_attributes) unless auth.extra_attributes.blank?
            successful_authenticator = auth
            break
          end

          auth_index += 1
        end

        if credentials_are_valid
          $LOG.info("Credentials for username '#{@username}' successfully validated using #{successful_authenticator.class.name}.")
          $LOG.debug("Authenticator provided additional user attributes: #{extra_attributes.inspect}") unless extra_attributes.blank?

          # 3.6 (ticket-granting cookie)
          tgt = generate_ticket_granting_ticket(@username, extra_attributes)
          response.set_cookie('tgt', tgt.to_s)

          $LOG.debug("Ticket granting cookie '#{tgt.inspect}' granted to #{@username.inspect}")

          if @service.blank?
            $LOG.info("Successfully authenticated user '#{@username}' at '#{tgt.client_hostname}'. No service param was given, so we will not redirect.")
            @message = {:type => 'confirmation', :message => t.notice.success_logged_in}
          else
            @st = generate_service_ticket(@service, @username, tgt)

            begin
              service_with_ticket = service_uri_with_ticket(@service, @st)

              $LOG.info("Redirecting authenticated user '#{@username}' at '#{@st.client_hostname}' to service '#{@service}'")
              redirect service_with_ticket, 303 # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
            rescue URI::InvalidURIError
              $LOG.error("The service '#{@service}' is not a valid URI!")
              @message = {
                :type => 'mistake',
                :message => t.error.invalid_target_service
              }
            end
          end
        else
          $LOG.warn("Invalid credentials given for user '#{@username}'")
          @message = {:type => 'mistake', :message => t.error.incorrect_username_or_password}
          status 401
        end
      rescue CASServer::AuthenticatorError => e
        $LOG.error(e)
        # generate another login ticket to allow for re-submitting the form
        @lt = generate_login_ticket.ticket
        @message = {:type => 'mistake', :message => e.to_s}
        status 401
      end

      render @template_engine, :login
    end

    get /^#{uri_path}\/?$/ do
      redirect "#{config['uri_path']}/login", 303
    end


    # 2.3

    # 2.3.1
    get "#{uri_path}/logout" do
      CASServer::Utils::log_controller_action(self.class, params)

      # The behaviour here is somewhat non-standard. Rather than showing just a blank
      # "logout" page, we take the user back to the login page with a "you have been logged out"
      # message, allowing for an opportunity to immediately log back in. This makes it
      # easier for the user to log out and log in as someone else.
      @service = clean_service_url(params['service'] || params['destination'])
      @continue_url = params['url']

      @gateway = params['gateway'] == 'true' || params['gateway'] == '1'

      tgt = CASServer::Model::TicketGrantingTicket.find_by_ticket(request.cookies['tgt'])

      response.delete_cookie 'tgt'

      if tgt
        CASServer::Model::TicketGrantingTicket.transaction do
          $LOG.debug("Deleting Service/Proxy Tickets for '#{tgt}' for user '#{tgt.username}'")
          tgt.granted_service_tickets.each do |st|
            send_logout_notification_for_service_ticket(st) if config[:enable_single_sign_out]
            # TODO: Maybe we should do some special handling if send_logout_notification_for_service_ticket fails?
            #       (the above method returns false if the POST results in a non-200 HTTP response).
            $LOG.debug "Deleting #{st.class.name.demodulize} #{st.ticket.inspect} for service #{st.service}."
            st.destroy
          end

          pgts = CASServer::Model::ProxyGrantingTicket.find(:all,
            :conditions => [CASServer::Model::ServiceTicket.quoted_table_name+".username = ?", tgt.username],
            :include => :service_ticket)
          pgts.each do |pgt|
            $LOG.debug("Deleting Proxy-Granting Ticket '#{pgt}' for user '#{pgt.service_ticket.username}'")
            pgt.destroy
          end

          $LOG.debug("Deleting #{tgt.class.name.demodulize} '#{tgt}' for user '#{tgt.username}'")
          tgt.destroy
        end

        $LOG.info("User '#{tgt.username}' logged out.")
      else
        $LOG.warn("User tried to log out without a valid ticket-granting ticket.")
      end

      @message = {:type => 'confirmation', :message => t.notice.success_logged_out}

      @message[:message] += t.notice.click_to_continue if @continue_url

      @lt = generate_login_ticket

      if @gateway && @service
        redirect @service, 303
      elsif @continue_url
        render @template_engine, :logout
      else
        render @template_engine, :login
      end
    end


    # Handler for obtaining login tickets.
    # This is useful when you want to build a custom login form located on a
    # remote server. Your form will have to include a valid login ticket
    # value, and this can be fetched from the CAS server using the POST handler.

    get "#{uri_path}/loginTicket" do
      CASServer::Utils::log_controller_action(self.class, params)

      $LOG.error("Tried to use login ticket dispenser with get method!")

      status 422

      t.error.login_ticket_needs_post_request
    end


    # Renders a page with a login ticket (and only the login ticket)
    # in the response body.
    post "#{uri_path}/loginTicket" do
      CASServer::Utils::log_controller_action(self.class, params)

      lt = generate_login_ticket

      $LOG.debug("Dispensing login ticket #{lt} to host #{(@env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_HOST'] || @env['REMOTE_ADDR']).inspect}")

      @lt = lt.ticket

      @lt
    end


		# 2.4

		# 2.4.1
    get "#{uri_path}/validate" do
      CASServer::Utils::log_controller_action(self.class, params)

      if ip_allowed?(request.ip)
        # required
        @service = clean_service_url(params['service'])
        @ticket = params['ticket']
        # optional
        @renew = params['renew']

        st, @error = validate_service_ticket(@service, @ticket)
        @success = st && !@error

        @username = st.username if @success
      else
        @success = false
        @error = Error.new(:INVALID_REQUEST, 'The IP address of this service has not been allowed')
      end

      status response_status_from_error(@error) if @error

      render @template_engine, :validate, :layout => false
    end


    # 2.5

    # 2.5.1
    get "#{uri_path}/serviceValidate" do
      CASServer::Utils::log_controller_action(self.class, params)

      # force xml content type
      content_type 'text/xml', :charset => 'utf-8'

      if ip_allowed?(request.ip)
        # required
        @service = clean_service_url(params['service'])
        @ticket = params['ticket']
        # optional
        @pgt_url = params['pgtUrl']
        @renew = params['renew']

        st, @error = validate_service_ticket(@service, @ticket)
        @success = st && !@error

        if @success
          @username = st.username
          if @pgt_url
            pgt = generate_proxy_granting_ticket(@pgt_url, st)
            @pgtiou = pgt.iou if pgt
          end
          @extra_attributes = st.granted_by_tgt.extra_attributes || {}
        end
      else
        @success = false
        @error = Error.new(:INVALID_REQUEST, 'The IP address of this service has not been allowed')
      end

      status response_status_from_error(@error) if @error

      render :builder, :proxy_validate
    end


    # 2.6

    # 2.6.1
    get "#{uri_path}/proxyValidate" do
      CASServer::Utils::log_controller_action(self.class, params)

      # force xml content type
      content_type 'text/xml', :charset => 'utf-8'

      if ip_allowed?(request.ip)

        # required
        @service = clean_service_url(params['service'])
        @ticket = params['ticket']
        # optional
        @pgt_url = params['pgtUrl']
        @renew = params['renew']

        @proxies = []

        t, @error = validate_proxy_ticket(@service, @ticket)
        @success = t && !@error

        @extra_attributes = {}
        if @success
          @username = t.username

          if t.kind_of? CASServer::Model::ProxyTicket
            @proxies << t.granted_by_pgt.service_ticket.service
          end

          if @pgt_url
            pgt = generate_proxy_granting_ticket(@pgt_url, t)
            @pgtiou = pgt.iou if pgt
          end

          @extra_attributes = t.granted_by_tgt.extra_attributes || {}
        end
      else
        @success = false
        @error = Error.new(:INVALID_REQUEST, 'The IP address of this service has not been allowed')
      end

      status response_status_from_error(@error) if @error

     render :builder, :proxy_validate
    end


    # 2.7
    get "#{uri_path}/proxy" do
      CASServer::Utils::log_controller_action(self.class, params)

      # required
      @ticket = params['pgt']
      @target_service = params['targetService']

      pgt, @error = validate_proxy_granting_ticket(@ticket)
      @success = pgt && !@error

      if @success
        @pt = generate_proxy_ticket(@target_service, pgt)
      end

      status response_status_from_error(@error) if @error

      render :builder, :proxy
    end



    # Helpers

    def response_status_from_error(error)
      case error.code.to_s
      when /^INVALID_/, 'BAD_PGT'
        422
      when 'INTERNAL_ERROR'
        500
      else
        500
      end
    end

    def serialize_extra_attribute(builder, key, value)
      if value.kind_of?(String)
        builder.tag! key, value
      elsif value.kind_of?(Numeric)
        builder.tag! key, value.to_s
      else
        builder.tag! key do
          builder.cdata! value.to_yaml
        end
      end
    end

    def compile_template(engine, data, options, views)
      super engine, data, options, @custom_views || views
    rescue Errno::ENOENT
      raise unless @custom_views
      super engine, data, options, views
    end

    def ip_allowed?(ip)
      require 'ipaddr'

      allowed_ips = Array(settings.config[:allowed_service_ips])

      allowed_ips.empty? || allowed_ips.any? { |i| IPAddr.new(i) === ip }
    end

    helpers do
      def authenticated?
        @authenticated
      end

      def authenticated_username
        @authenticated_username
      end
    end
  end
end
