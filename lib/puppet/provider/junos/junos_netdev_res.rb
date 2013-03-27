=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_netdev_log.rb
* Version        : 2012-11-09
* Platform       : All Junos
* Description    : 
*
*    This file contains the code responsible for resources
*    (vlans, l2-interfaces, etc.) that are used by the 
*    provider child classes.  The resource class models the 
*    data collection management for any give Junos object. 
*    Each Provider object will create a NetdevJunos::Resource
*    object for processing the Provider properties.  
*    The act of instantiating this class will trigger the 
*    creation of the "global" NetdevJunos::Device object 
*    through the use of the 'netdev_get' method
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


require 'net/netconf/jnpr'

module NetdevJunos
  
  class Resource < Netconf::JunosConfig
    
    attr_reader :edit_item, :rpc
    
    def initialize( pp_obj, edit_path, edit_item = nil )
      @edit_path = edit_path
      @edit_item = edit_item
      super( :edit => edit_path, :build => method(:netdev_on_makeconfig_xml) )
      
      @pp_obj = pp_obj   
      @property_hash = pp_obj.instance_variable_get(:@property_hash)
      
      @rpc = pp_obj.netdev_get.netconf.rpc      
      
      @ndev_hash = Hash.new   
      @ndev_hash[:active] = :true    # config items are active by default
    end
    
    ##### ------------------------------------------------------------
    ##### Hash/parameter methods
    ##### ------------------------------------------------------------
    
    def [](key)
      @ndev_hash[key]
    end
    
    def []=(key,value)
      @ndev_hash[key] = value
    end
    
    def update( name )
      return if defined? @deleted
      self << {:name => name }      
    end   
    
    def del( name )
      self << { :name => name, :junos_delete => true }
      @deleted = true     
    end
    
    ### this method gets called when the provider
    ### adds the resource contents to the NetdevJunos
    ### managed object.  Refer to NetdevJunos#edit_config
    
    def netdev_on_makeconfig_xml( xml, netdev_res )
      
      if netdev_res[:junos_delete]
        @pp_obj.netdev_resxml_delete( xml )
        return
      end        
      
      if @property_hash.empty?      
        
        @top_xml ||= @pp_obj.netdev_resxml_top( xml )
        unless @pp_obj.ndev_res[:unmanaged_active]
          unless @pp_obj.resource[:active] == @pp_obj.ndev_res[:active]
            @pp_obj.netdev_resxml_change_active( @top_xml ) 
          end
        end
        dot = @pp_obj.netdev_resxml_edit( @top_xml )
        @pp_obj.netdev_resxml_new( dot )       
        
      else
                
        @top_xml ||= @pp_obj.netdev_resxml_top( xml )
        
        if @property_hash.delete :active
          @pp_obj.netdev_resxml_change_active( xml )
        end
        
        dot = @pp_obj.netdev_resxml_edit( @top_xml )         
        @property_hash.each do |k,v|
          @pp_obj.send("xml_change_#{k}", dot ) 
        end               
        
      end    
      
    end
    
    ### ------------------------------------------------------------
    ###   This following is used to generate the XML needed to
    ###   get the configuration for the given resource from device
    ### ------------------------------------------------------------  
    
    def netdev_resxml_top
      cfg = Netconf::JunosConfig.new(:TOP)
      xml = cfg.doc
      at_ele = cfg.edit_path( xml, @edit_path ) 
      Nokogiri::XML::Builder.with( at_ele ) do |dot|
        @pp_obj.netdev_resxml_top( dot )
      end
      return xml      
    end
    
    def getconfig      
      got_config = @rpc.get_configuration( netdev_resxml_top )
    end
    
    ### ------------------------------------------------------------
    ###   Utility Methods
    ### ------------------------------------------------------------  
    
    # method to extract the 'active/inactive' state
    # from the Junos configuration item.
    
    def set_active_state( ndev_xml )
      @ndev_hash[:active] = ndev_xml['inactive'] ? :false : :true          
      @pp_obj.ndev_res[:name] = @pp_obj.resource[:name]
      ndev_xml
    end
    
    def is_new?
      return @ndev_hash[:name].nil?
    end
    
  end
end
