require 'rest_client'
require 'tempfile'

transport_type = :razor

require 'pathname' # workaround not necessary in newer versions of Puppet
mod = Puppet::Module.find('transport', Puppet[:environment].to_s)
require File.join mod.path, 'lib/puppet_x/puppetlabs/transport'
begin
    require 'puppet_x/puppetlabs/transport/razor'
rescue LoadError => e
  require 'pathname' # WORK_AROUND #14073 and #7788
  module_lib = Pathname.new(__FILE__).parent.parent.parent
  require File.join module_lib, "puppet_x/puppetlabs/transport/#{transport_type}"
end

class Puppet::Provider::Razor < Puppet::Provider

  def get(type, name, action = nil)
    begin
      @conn ||= setup_transport
      response = @conn["collections/#{[type, name, action].compact.join('/')}"].get
    rescue RestClient::ResourceNotFound
      return false
    end
    if response.code == 200
      PSON.parse(response)
    else
      raise(Exception, "Error: http status code #{response.code}\n#{response.to_str}")
    end
  end

  def post(url, args)
    begin
      @conn ||= setup_transport
      response = @conn["commands/#{url}"].post args.to_pson, {:content_type => :json, :accept => :json}
    rescue Exception => e
      fail("Rest call failed: #{e.response}")
    end
    unless response.code == 202
      raise(Exception, "Error: http status code #{response.code}\n#{response.to_str}")
    end
    response.code
  end

  def setup_transport
      @transport ||= PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => resource[:transport], :catalog => resource.catalog, :provider => 'razor')
      @conn = @transport.connect
  end

  # take a hash, and convert it into a temporary
  # json file that can be passed to the razor command
  def process_json_args(args = {})
    @tmp_json_file = Tempfile.new('razor_json')
    json = args.to_pson
    @tmp_json_file.write(json)
    @tmp_json_file.close
    "--json #{@tmp_json_file.path}"
  end

end
