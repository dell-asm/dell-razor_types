module PuppetX::Puppetlabs::Transport
  class Razor
    attr_reader :name

    def initialize(opts)
      @name = opts[:name]
      options  = opts[:options] || {}
      @options = options.inject({}){|h, (k, v)| h[k.to_sym] = v; h}
      @options[:host]     = opts[:server]
      @options[:user]     = opts[:username]
      @options[:password] = opts[:password]
      @options[:scheme] ||= 'http'
      @options[:port] ||= '80'
    end

    def connect
      if @options[:url]
        uri = URI.parse(@options[:url])
        @options[:username] = uri.user
        @options[:password] = uri.password
        @options[:host] = uri.host
        @options[:scheme] = uri.scheme
        @options[:port] = uri.port
        @options[:path] = uri.path
      end
      if @options[:client_cert]
        @options[:cert] = OpenSSL::X509::Certificate.new(File.read(@options[:client_cert]))
        @options[:key] = OpenSSL::PKey::RSA.new(File.read(@options[:client_cert]))
        @options[:scheme] = 'https'
      end
      url = "#{@options[:scheme]}://#{@options[:host]}:#{@options[:port]}/#{@options[:path]}"
      RestClient::Resource.new(url,
                               :ssl_client_cert => @options[:cert],
                               :ssl_client_key => @options[:key],
                               :user => @options[:user],
                               :password => @options[:password],
                               :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
    end

    def config
      @options
    end

  end
end