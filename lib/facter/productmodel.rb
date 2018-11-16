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

Facter.add(:productmodel) do
  setcode do
     require 'net/netconf/jnpr/ioproc'
     ndev = Netconf::IOProc.new
     ndev.open
     inv_info = ndev.rpc.get_chassis_inventory
     errs = inv_info.xpath('//output')[0]

     if errs and errs.text.include? "This command can only be used on the master routing engine"
        raise Junos::Ez::NoProviderError, "Puppet can only be used on master routing engine !!"
     end

     chassis = inv_info.xpath('chassis')
     ndev.close
     #Return chassis description which contains productmodel. 
     chassis.xpath('description').text
  end
end
