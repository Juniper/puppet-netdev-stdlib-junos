=begin
* Puppet Module  : Provder: netdev
* Author         : Ganesh Nalawade
* File           : junos_groups.rb
* Version        : 2014-11-10
* Platform       : EX | QFX | MX
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

class Puppet::Provider::Junos::Group < Puppet::Provider::Junos 

  ### ---------------------------------------------------------------  
  ### triggered from Provider #exists?
  ### ---------------------------------------------------------------  
  
  def netdev_res_exists?
    resource[:format] ||=  'xml'
    return false unless ( grp = init_resource )
    @ndev_res[:name] = grp.xpath('name').text.chomp
    return true     
  end

  ### ---------------------------------------------------------------
  ### called from #netdev_exists?
  ### ---------------------------------------------------------------  
  
  def init_resource
    @ndev_res ||= NetdevJunos::Resource.new( self, "groups" ) 
    
    resource[:format] ||= 'xml'
    ndev_config = @ndev_res.getconfig
       
    raise ArgumentError unless resource[:path]
    
    grp = ndev_config.xpath("//groups[name=\'#{resource[:name]}\']")[0]
    if grp
      @ndev_res.set_active_state( grp )
    end
    load
 
    if grp then return grp else return false end
  end   


  def load
    return @config = nil if ( resource[:ensure] == :absent )
    admin = '' 
   if resource[:format].to_s == 'set'
      @config =  "\ndelete groups #{resource[:name]}\n" +
                   "edit groups #{resource[:name]}\n" + 
                    File.read( resource[:path] ) 
      unless resource[:active] == @ndev_res[:active]
        admin = resource[:active] == :false ? 'deactivate' : 'activate'
        @config += "\nquit\n"
        @config += "\n#{admin} groups #{resource[:name]}"
      end

    elsif resource[:format].to_s == 'text'
      unless resource[:active] == @ndev_res[:active]
        admin = resource[:active] == :false ? 'inactive' : 'active'
      end
      admin += ": " unless admin.empty? 
      @config = "groups {\n#{admin} replace: #{resource[:name]} {\n" + 
                File.read( resource[:path] ) + "\n}\n}"

    elsif resource[:format].to_s == 'xml'
      @config = File.read( resource[:path])
    end
  end
 
 
  ##### -------------------------------------------------------------
  ##### XML builder methods
  ##### -------------------------------------------------------------  
  def xml_change_path( xml )
  end

  def xml_change_format( xml )
  end

  ##### ------------------------------------------------------------
  #####              XML Resource Building
  ##### ------------------------------------------------------------   
  
  # override default 'top' method 
  def netdev_resxml_top( xml )
    xml.name resource[:name]
    par = xml.instance_variable_get(:@parent)
    par['replace'] = 'replace' unless resource[:ensure] == :absent
    return xml
  end

  def netdev_resxml_edit( xml )
    if @config  
      xml << @config
    end 
    return xml
  end

  def get_format
     if properties.include? :format and @config
       return resource[:format]
     end
     return :xml
  end

  def apply_groups
    cfg = Netconf::JunosConfig.new(:TOP)
    xml = cfg.doc
    Nokogiri::XML::Builder.with( xml.at_xpath( 'configuration' )) do |dot|
      if @config and resource[:active] == :true  
        dot.send :'apply-groups', resource[:name] 
      else 
        dot.send :'apply-groups', resource[:name], Netconf::JunosConfig::DELETE
      end
    end
    @@netdev.edit_config( xml, "xml" )
  end  

  def config_update( name )
    @ndev_res.update name
    @format = get_format
    if (@format == :set ) or (@format == :text )
      @@netdev.edit_config( @config, @format.to_s )
    else
      @@netdev.edit_config( @ndev_res, "xml" )
    end
    
    if @@netdev.edits_count
      apply_groups
    end

  end

  ##### ------------------------------------------------------------
  ##### Device provider methods expected by Puppet
  ##### ------------------------------------------------------------

  def flush
    ## handle netdev_group attribute change     
    if netdev_res_exists?
      if resource[:ensure] == :absent or 
         resource[:active] != @ndev_res[:active]
        Puppet::Provider::Junos.instance_method(:flush).bind(self).call  
      else
        Puppet.debug( "#{self.resource.type}:: Nothing to flush #{resource[:name]}" ) 
      end
    elsif resource[:ensure] == :present
      Puppet::Provider::Junos.instance_method(:flush).bind(self).call
    else
      Puppet.debug( "#{self.resource.type}:: Nothing to flush #{resource[:name]}" )
    end    
     
  end

  def refresh
    ## handle refresh event from file resource types
    Puppet.debug( "#{self.resource.type}: REFRESH #{resource[:name]}" )
    Puppet::Provider::Junos.instance_method(:flush).bind(self).call
  end

end  
