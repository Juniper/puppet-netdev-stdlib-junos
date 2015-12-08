=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : puppet/provider/network_trunk/junos.rb
* Version        : 2012-11-07
* Platform       : EX | QFX | SRX
* Description    : 
*
*    The Provider class definition to implement the
*    network_interface type.  There isn't really anything in
*    this file; refer to puppet/provider/junos.rb for details.
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

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","..",".."))

require 'puppet/provider/junos/junos_interface'

Puppet::Type.type(:network_interface).provide(:junos_switch, :parent => Puppet::Provider::Junos::Interface) do
  @doc = "Junos Physical Interface"

  has_feature :activable
  confine :junos_ifd_style => :switch
  confine :junos_switch_style => :vlan  
  ### invoke class method to autogen the default property methods for both Puppet
  ### and the netdev module.  That's it, yo!

  mk_resource_methods    
  mk_netdev_resource_methods  
  
end

require 'puppet/provider/junos/junos_interface_classic'

Puppet::Type.type(:network_interface).provide(:junos_classic, :parent => Puppet::Provider::Junos::InterfaceClassic) do
  @doc = "Junos Physical Interface, Classic Style"
  
  has_feature :activable
  confine :junos_ifd_style => [:classic, :switch]
  confine :junos_switch_style => [:vlan_l2ng, :bridge_domain]  
  ### invoke class method to autogen the default property methods for both Puppet
  ### and the netdev module.  That's it, yo!

  mk_resource_methods    
  mk_netdev_resource_methods  
  
end
