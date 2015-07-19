require 'openssl'
require 'restclient'

module PuppetX::Puppetlabs::Transport
  class Razor
    attr_reader :name

    def initialize(opts)
      @name = opts[:name]

      @options = opts[:options].inject({}){|h, (k, v)| h[k.to_sym] = v; h} || {}
      @options[:user]     = opts[:username] if opts[:username]
      @options[:password] = opts[:password] if opts[:password]

      [[:ssl_client_cert, OpenSSL::X509::Certificate],
       [:ssl_client_key, OpenSSL::PKey::RSA]].each do |key, init_class|
        if @options[key].is_a?(String) && File.exists?(@options[key])
          @options[key] = init_class.new(File.read(@options[key]))
        end
      end

      unless (@url = @options.delete(:url))
        # Build default razor api url from transport parameters
        @url = "http://#{opts[:server] || 'localhost'}:8080/api"
      end
    end

    def connect
      RestClient::Resource.new(@url, @options)
    end

    def config
      @options
    end

  end
end