=begin
* Puppet Module  : netdev
* Author         : Ganesh Nalawade
* File           : puppet/type/netdev_group.rb
* Version        : 2014-11-10
* Description    : 
*
*    This file contains the Type definition for the JUNOS
*    Group Configuration.  The network device module 
*    separates the physical port controls from the service 
*    function.  Service controls are defined in their
*    respective type files; e.g. netdev_group.rb
*
=end

Puppet::Type.newtype(:netdev_group) do
  @doc = "Network Device Group Configuration"
  
  feature :refreshable, "The provider can restart the service.",
     :methods => [:restart]

  ensurable
  feature :activable, "The ability to activate/deactive configuration"  
  
  ##### -------------------------------------------------------------    
  ##### Parameters
  ##### -------------------------------------------------------------    
  
  newparam( :name, :namevar=>true ) do
    desc "Group Name"
  end
  
  ##### -------------------------------------------------------------
  ##### Properties
  ##### -------------------------------------------------------------  
  
  newproperty( :active, :required_features => :activable ) do
    desc "Config activation"
    defaultto(:true)
    newvalues(:true, :false)
  end   
  
  newproperty( :path, :namevar => true ) do
    desc "Path of JUNOS configuration file"
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        fail Puppet::Error, "File paths must be fully qualified, not '#{value}'"
      end
    end
    
    munge do |value|
      ::File.expand_path(value)
    end    
  end
  
  
  newproperty( :format ) do
    desc "JUNOS configuration format [set|conf|xml]"
    defaultto( "xml" )
    newvalues( "text", "set", "xml" )    
  end
 
  ##### -------------------------------------------------------------
  ##### Auto require the domain_name resource - 
  #####   There must be one domain_name resource defined in the
  #####   catalog, it doesn't matter what the name of the device is,
  #####   just that one exists.  
  ##### ------------------------------------------------------------- 
  
  autorequire(:domain_name) do    
    netdev = catalog.resources.select{ |r| r.type == :domain_name }[0]
    raise "No domain_name found in catalog" unless netdev
    netdev.title   # returns the name of the domain_name resource
  end  
  
  def refresh
    provider.refresh
  end  
end

