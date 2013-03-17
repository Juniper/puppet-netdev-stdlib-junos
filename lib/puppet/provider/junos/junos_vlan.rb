=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_vlan.rb
* Version        : 2012-11-07
* Platform       : EX | QFX | SRX
* Description    : 
*
*   This file contains the Junos specific code to control basic
*   VLAN configuration on platforms that support the [edit vlans]
*   hierarchy.
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

require 'puppet/provider/junos/junos_parent'

class Puppet::Provider::Junos::Vlan < Puppet::Provider::Junos
  
  ### --------------------------------------------------------------------
  ### triggered by provider #exists? 
  ### --------------------------------------------------------------------  
  
  def netdev_res_exists?  
    
    return false unless (vlan_config = init_resource)

    @ndev_res[:vlan_id] = vlan_config.xpath('vlan-id').text.chomp
    @ndev_res[:description] = vlan_config.xpath('description').text.chomp
    @ndev_res[:no_mac_learning] = vlan_config.xpath('no-mac-learning').empty? ? :false : :true
        
    return true
  end   

  ### --------------------------------------------------------------------  
  ### #netdev_retrieve helpers
  ### --------------------------------------------------------------------    
  
  def init_resource
    
    resource[:description] ||= default_description
    
    @ndev_res ||= NetdevJunos::Resource.new( self, "vlans", "vlan" )             
    
    return nil unless (ndev_config = @ndev_res.getconfig)
    
    return nil unless vlan_config = ndev_config.xpath('//vlan')[0]    
    
    @ndev_res.set_active_state( vlan_config )    
    
    return vlan_config
  end  
  
  def default_description
    "Puppet created VLAN: #{resource[:name]}: #{resource[:vlan_id]}"
  end
  
  ##### ------------------------------------------------------------
  ##### XML builder routines, one for each property
  ##### ------------------------------------------------------------   
  
  def xml_change_vlan_id( xml )
    xml.send :"vlan-id", resource[:vlan_id]
    on_change_vlan_id( xml )    
  end
  
  def xml_change_description( xml )
    xml.description resource[:description]
  end   
  
  def xml_change_no_mac_learning( xml )
    ml = resource[:no_mac_learning] == :false
    return if @ndev_res.is_new? and ml
    
    xml.send( :'no-mac-learning', ml ? Netconf::JunosConfig::DELETE : nil )
  end
  
  def on_change_vlan_id( xml )
    return unless Facter.value('junos_switch_style') == 'vlan_l2ng'
    
    # because the L2NG codes the vlan-id values into the interfaces,
    # we now need to update all instances of the use of the vlan. Yo!
    # so the trick here is to create a false-name by prepending a 
    # tilde (~) before the vlan_name.  Then tinker with the 
    # associated  netdev_l2_interface properties so that it
    # triggers the resource to 'do the right thing'.  There is
    # a dependency in the netdev_l2_interface code on the use
    # of the '~' so be aware if you want to muck with it.  Yo!
    
    vlan_name = resource[:name]
    vlan_name_new = '~' + vlan_name
    
    vlan_old = [[ vlan_name ]]
    vlan_new = [[ vlan_name_new ]]
    
    catalog = resource.catalog
    
    rpc = @ndev_res.rpc
    bd_info = rpc.get_vlan_information( :vlan_name => vlan_name )
    intfs = bd_info.xpath('//l2ng-l2rtb-vlan-member-interface')
    
    intfs.each do |x_int|
      ifd_name = x_int.text[/(.*)\./,1]
      if l2_intf = catalog.resource( :netdev_l2_interface, ifd_name )
        if l2_intf[:tagged_vlans].include? [vlan_name]
          l2_intf[:tagged_vlans] = l2_intf[:tagged_vlans] - vlan_old + vlan_new
        end
        l2_intf[:untagged_vlan] = vlan_name_new if l2_intf[:untagged_vlan] == vlan_name
      else
        NetdevJunos::Log.err "Unmanaged VLAN interface: #{ifd_name}"
      end
    end
    
  end  
  
end
