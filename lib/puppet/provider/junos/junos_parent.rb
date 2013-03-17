=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : puppet/provider/junos.rb
* Version        : 2012-11-07
* Platform       : EX | QFX | SRX
* Description    : 
*
*    This file contains the Parent Provider class for all Junos
*    Provider classes.  This is the *workhorse* of the code
*    that encapsulates the main processing tasks.
*
* Copyright (c) 2012  Juniper Networks. All Rights Reserved.
*
* YOU MUST ACCEPT THE TERMS OF THIS DISCLAIMER TO USE THIS SOFTWARE, 
* IN ADDITION TO ANY OTHER LICENSES AND TERMS REQUIRED BY JUNIPER NETWORKS.
* 
* JUNIPER IS WILLING TO MAKE THE INCLUDED SCRIPTING SOFTWARE AVAILABLE TO YOU
* ONLY UPON THE CONDITION THAT YOU ACCEPT ALL OF THE TERMS CONTAINED IN THIS
* DISCLAIMER. PLEASE READ THE TERMS AND CONDITIONS OF THIS DISCLAIMER
* CAREFULLY.
*
* THE SOFTWARE CONTAINED IN THIS FILE IS PROVIDED "AS IS." JUNIPER MAKES NO
* WARRANTIES OF ANY KIND WHATSOEVER WITH RESPECT TO SOFTWARE. ALL EXPRESS OR
* IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING ANY WARRANTY
* OF NON-INFRINGEMENT OR WARRANTY OF MERCHANTABILITY OR FITNESS FOR A
* PARTICULAR PURPOSE, ARE HEREBY DISCLAIMED AND EXCLUDED TO THE EXTENT
* ALLOWED BY APPLICABLE LAW.
*
* IN NO EVENT WILL JUNIPER BE LIABLE FOR ANY DIRECT OR INDIRECT DAMAGES, 
* INCLUDING BUT NOT LIMITED TO LOST REVENUE, PROFIT OR DATA, OR
* FOR DIRECT, SPECIAL, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES
* HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY ARISING OUT OF THE 
* USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF JUNIPER HAS BEEN ADVISED OF 
* THE POSSIBILITY OF SUCH DAMAGES.
=end

require 'puppet/provider/junos/junos_netdev'

class Puppet::Provider::Junos < Puppet::Provider
  
  attr_accessor :ndev_res
  
  ##### ------------------------------------------------------------   
  ##### Device provider methods expected by Puppet
  ##### ------------------------------------------------------------  
  
  def create
    Puppet.debug( "#{self.resource.type}: CREATE #{resource[:name]}" ) 
  end
  
  def destroy
    Puppet.debug( "#{self.resource.type}:: DESTROY #{resource[:name]}" )
    config_del resource[:name]
  end
  
  def exists?
    Puppet.debug( "#{self.resource.type}: checking #{resource[:name]}" ) 
    return false unless netdev_res_exists?
    netdev_res_property :name
  end
    
  def flush
    if defined? @ndev_res[:name]
      Puppet.debug( "#{self.resource.type}:: Flusing #{resource[:name]}" ) 
      config_update resource[:name]     
    else
      Puppet.debug( "#{self.resource.type}:: Nothing to flush #{resource[:name]}" )       
    end
  end     
  
  def netdev_create
    @@netdev ||= NetdevJunos::Device.new( resource.catalog.version )
    netdev_get
  end
  
  def netdev_get
    return (@@netdev.ready) ? @@netdev : nil
  end  
      
  ##### ------------------------------------------------------------   
  ##### Provider class methods to automatically build property
  ##### reader methods
  ##### ------------------------------------------------------------   
  
  def self.netdev
    return (@@netdev.ready) ? @@netdev : nil
  end
  
  def self.mk_netdev_resource_methods
    (resource_type.validproperties - [:ensure]).each do |prop|
      prop_sym = symbolize(prop)
      define_method(prop_sym) do
        netdev_res_property( prop_sym )
      end
    end
  end
  
  def netdev_res_property(key)
    @ndev_res[key]
  end   
  
  def properties
    self.class.resource_type.validproperties.flatten - [:ensure, :active]    
  end  
  
  ##### ------------------------------------------------------------   
  ##### Methods that build up the configuration changes
  ##### ------------------------------------------------------------   
  
  def config_update( name )
    @ndev_res.update name
    @@netdev.edit_config( @ndev_res )
  end
  
  def config_del( name )
    @ndev_res.del name
    # do not invoke @@netdev.edit_config ... just mark the
    # item for deletion and it will get picked up by a later
    # call to config_edit in #flush
  end
  
  ##### ------------------------------------------------------------
  ##### Methods that generate the XML associated with changes   
  ##### ------------------------------------------------------------
  
  # put the 'dot' inside the top of the config item
  
  def netdev_resxml_top( xml )
    xml.send( @ndev_res.edit_item ) { 
      xml.name resource[:name] 
      return xml
    }
  end
  
  # default edit 'dot' assumes top
  
  def netdev_resxml_edit( xml )      
    return xml
  end
  
  # mark the config item for delete
  
  def netdev_resxml_delete( xml )
    top = netdev_resxml_top( xml )
    par = top.instance_variable_get(:@parent)
    par['delete'] = 'delete'
  end
  
  # mark the config item for 'active' or 'inactive'
  # this assumes the caller has already set xml to top
  
  def netdev_resxml_change_active( xml )
    par = xml.instance_variable_get(:@parent)
    admin = resource[:active] == :false ? 'inactive' : 'active'
    par[admin] = admin
  end   
  
  # this assumes the caller has already set xml
  # to the 'edit' of the config item
  
  def netdev_resxml_new( edit_xml )
    self.properties.each do |p|         
      self.send("xml_change_#{p}", edit_xml )          
    end
  end   
  
end





