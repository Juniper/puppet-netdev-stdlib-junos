$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","..",".."))

require 'puppet/provider/junos/junos_parent'

Puppet::Type.type(:netdev_device).provide(:junos, :parent => Puppet::Provider::Junos) do
  
  @doc = "Junos Device Managed Resource for auto-require"
  
  ##### ------------------------------------------------------------   
  ##### Device provider methods expected by Puppet
  ##### ------------------------------------------------------------  

  def exists?  
    ready = netdev_create
    raise "Unable to obtain Junos configuration exclusive lock" unless ready
    true
  end
  
  def create
    raise "Unreachable: NETDEV create"    
  end

  def destroy
    raise "Unreachable: NETDEV destroy"        
  end
  
  def flush
    raise "Unreachable: NETDEV flush"        
  end

end
