# Fact: productmodel
#
# Purpose:
#   Returns the product model of the system.
#
# Test:
# # facter -p productmodel
# JNP10003-160C [PTX10003-160C]
#
# Caveats:
#

is_docker = (Facter.value(:container) == "docker")

Facter.add(:productmodel) do
  setcode do

    # In case of docker container, open a NETCONF/SSH session
    if is_docker
      require 'net/netconf/jnpr'
      # NETCONF_USER refers to the login username configured for puppet operations
      login = { target: 'localhost', username: ENV['NETCONF_USER'], port:22 }
      @netconf = Netconf::SSH.new(login)
    # Else, open an IOProc session
    else
      require 'net/netconf/jnpr/ioproc'
      @netconf = Netconf::IOProc.new
    end
    @netconf.open
    inv_info = @netconf.rpc.get_chassis_inventory
    errs = inv_info.xpath('//output')[0]

    if errs && errs.text.include?('This command can only be used on the
                        master routing engine')
      raise Junos::Ez::NoProviderError, 'Puppet can only be used on
                        master routing engine !!'
    end

    chassis = inv_info.xpath('chassis')
    @netconf.close
    # Return chassis description which contains productmodel.
    chassis.xpath('description').text
  end
end