module ApplicationHelper

  # how to use
  # postRequest({command: "listTemplates", templatefilter: "executable" })
  def postRequest args
    begin
      dargs = args.deep_dup
      uri = URI.parse(Bkclient::Application.config.cloudstack[:apiURL])
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new(uri.request_uri)
      str = ""
      dargs.merge!({apiKey: Bkclient::Application.config.cloudstack[:apiKey]}).sort.each{|k,v| str += "#{k}=#{v}&"}
      str = str[0..-2].downcase.gsub(' ', '%20')
      dargs.merge!({signature: genSignature(str) })
      req.set_form_data( dargs )
      response = http.request(req)
    rescue
      response = "connection error"
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      return Hash.from_xml(response.body)
    when "error"

    else
      # return response
    end
  end

  def getRequest args
    begin
      dargs = args.deep_dup
      uri = URI.parse(Bkclient::Application.config.cloudstack[:apiURL])
      str = ""
      dargs.merge!({apiKey: Bkclient::Application.config.cloudstack[:apiKey]}).sort.each{|k,v| str += "#{k}=#{v}&"}
      str = str[0..-2].downcase.gsub(' ', '%20')
      dargs.merge!({signature: genSignature(str) })
      uri.query = URI.encode_www_form(dargs)

      response = Net::HTTP.get_response(uri)
    rescue
      response = "connection error"
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      return Hash.from_xml(response.body)
    when "error"

    else
      # return response
    end
  end

  def genSignature str
    return Base64.encode64(HMAC::SHA1.digest(Bkclient::Application.config.cloudstack[:secretKey], str)).chomp
  end

  def getOSName str
    case true
    when /centos/i.match(str) != nil
      return "centos"
    when /fedora/i.match(str) != nil
      return "fedora"
    when /ubuntu/i.match(str) != nil
      return "ubuntu"
    when /debian/i.match(str) != nil
      return "debian"
    when /windows/i.match(str) != nil
      return "windows"
    else
      return "unknown"
    end
  end

end
