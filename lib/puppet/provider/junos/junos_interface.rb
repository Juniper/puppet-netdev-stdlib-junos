=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_interface.rb
* Version        : 2012-12-04
* Platform       : EX | QFX 
* Description    : 
*
*   This file contains the Junos specific code to control basic
*   Physical interface configuration on platforms that support 
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

class Puppet::Provider::Junos::Interface < Puppet::Provider::Junos 

  ### ---------------------------------------------------------------  
  ### triggered from Provider #exists?
  ### ---------------------------------------------------------------  
  
  def netdev_res_exists?
        
    return false unless (ifd = init_resource)
    
    @ndev_res[:description] = ifd.xpath('description').text.chomp
    @ndev_res[:admin] = ifd.xpath('disable').empty? ? :up : :down
    @ndev_res[:mtu] = (mtu = ifd.xpath('mtu')[0]).nil? ? -1 : mtu.text.to_i
    
    phy_options = ifd.xpath('ether-options')
    
    if phy_options.empty?
      @ndev_res[:speed] = :auto
      @ndev_res[:duplex] = :auto
    else 
      
      @ndev_res[:duplex] = case phy_options.xpath('link-mode').text.chomp
        when 'full-duplex' then :full
        when 'half-duplex' then :half
        else :auto
      end
      
      if speed = phy_options.xpath('speed')[0]
        @ndev_res[:speed] = speed_from_junos( speed.first_element_child.name )
      else
        @ndev_res[:speed] = :auto
      end
    end
    
    return true     
  end

  ### ---------------------------------------------------------------
  ### called from #netdev_exists?
  ### ---------------------------------------------------------------  
  
  def init_resource
    
    resource[:mtu] ||= -1    
    resource[:description] ||= default_description
    
    @ndev_res ||= NetdevJunos::Resource.new( self, "interfaces", "interface" ) 
    
    ndev_config = @ndev_res.getconfig
    return false unless (ifd = ndev_config.xpath('//interface')[0])
    
    @ndev_res.set_active_state( ifd )
    return ifd
  end   
  
  def default_description
    "Puppet created interface: #{resource[:name]}"
  end
  
  def speed_to_junos( pval )
    case pval
       when :'1g' then :'ethernet-1g'
       when :'100m' then :'ethernet-100m'
       when :'10m' then :'ethernet-10m'
       else :auto
    end        
  end
  
  def speed_from_junos( jval )
    case jval
      when 'ethernet-100m' then :'100m'
      when 'ethernet-10m' then :'10m'
      when 'ethernet-1g' then :'1g'
      else :auto
    end
  end
  
  ##### -------------------------------------------------------------
  ##### XML builder methods
  ##### -------------------------------------------------------------  
  
  def xml_change_mtu( xml )
    if resource[:mtu] > 0
      xml.mtu resource[:mtu]
    else
      xml.mtu( Netconf::JunosConfig::DELETE )
    end
  end
  
  def xml_change_admin( xml )
    return xml.disable if resource[:admin] == :down
    return if @ndev_res.is_new?
    # must be up
    xml.disable Netconf::JunosConfig::DELETE
  end
  
  def xml_change_description( xml )
    xml.description resource[:description]
  end
  
  def xml_change_speed( xml )         
    xml.send(:'ether-options') {
      xml.speed {
        if resource[:speed] == :auto
          if not @ndev_res.is_new?
            jval = speed_to_junos( @ndev_res[:speed] )
            xml.send( jval, Netconf::JunosConfig::DELETE )
          end
        else
          xml.send( speed_to_junos( resource[:speed] ))
        end
      }
    }    
  end
  
  def xml_change_duplex( xml )     
    xml.send(:'ether-options') {
      if resource[:duplex] == :auto
        unless @ndev_res.is_new?
          xml.send( :'link-mode', Netconf::JunosConfig::DELETE )
        end
      else
        xml.send( :'link-mode', case resource[:duplex]
           when :full then 'full-duplex'
           when :half then 'half-duplex'
        end )
      end
    }    
  end
  
end
