=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_lag.rb
* Version        : 2012-12.03
* Platform       : EX | QFX 
* Description    : 
*
*   This file contains the Junos specific code to control basic
*   Link Aggregation Group (LAG) controls
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

class Puppet::Provider::Junos::LAG < Puppet::Provider::Junos 
  
  ### ---------------------------------------------------------------  
  ### triggered from Provider #exists?
  ### ---------------------------------------------------------------  
  
  def netdev_res_exists?   
    
    ### need to setup the @ifd_ether_options before we return anything
    ### since this will be used in the case of a yet-to-be-created LAG
    
    if Facter.value(:junos_ifd_style) == 'classic'
      # all ports in the LAG must be of the same type, so check the first one
      # and use it to determine the options stanza name.  yo.
      l_0 = resource[:links][0].to_s
      @ifd_ether_options = (l_0.start_with? 'fe-') ? 'fastether-options' : 'gigether-options'
    else
      # switching platforms are standardized on the same stanza name. 
      @ifd_ether_options = 'ether-options'    
    end    
    
    return false unless ae_config = init_resource   
    
    nc = netdev_get.netconf.rpc
  
    # -------------------------------------------    
    # PROPERTY: links
    # -------------------------------------------
    # retrieve details on the ae interface so we can pull the list of member links.  In the general
    # case there could be a lot of sub-interfaces (units), so we need to handle that case here.  We
    # only want the IFD names in the @ndev_res hash
    
    @ndev_res[:links] = get_cookie_links( ae_config ) || []
    
    # -------------------------------------------    
    # PROPERTY: minimum_links
    # -------------------------------------------
    
    if mlinks = ae_config.xpath('aggregated-ether-options/minimum-links')[0]
      @ndev_res[:minimum_links] = mlinks.text.chomp.to_i;
    else
      @ndev_res[:minimum_links] = 0
    end 

    # -------------------------------------------    
    # PROPERTY: lacp
    # -------------------------------------------
    
    lacp = ae_config.xpath('aggregated-ether-options/lacp')[0]
    if lacp
      @ndev_res[:lacp] = :active if lacp.xpath('active')[0]
      @ndev_res[:lacp] = :passive if lacp.xpath('passive')[0]
    else
      @ndev_res[:lacp] = :disabled
    end
   
    return true
  end   
    
  ### ---------------------------------------------------------------
  ### called from #netdev_exists?
  ### ---------------------------------------------------------------  
  
  def init_resource
  
    @ndev_res ||= NetdevJunos::Resource.new( self, 'interfaces', 'interface' )       
    ndev_config = @ndev_res.getconfig    

    return nil unless lagcfg = ndev_config.xpath( '//interface')[0] 
    
    @ndev_res.set_active_state( lagcfg )         
    return lagcfg
  end

  ### ---------------------------------------------------------------
  ### Overriding Parent methods
  ### ---------------------------------------------------------------  
  
  def destroy    
    Puppet.debug( "#{self.resource.type}::LAG-DESTROY #{resource[:name]}" )
    
    # we need to load the known IFD ports in the lag so we can unbind them
    # from the lag.  We 'trick' the Puppet agent into processing the 
    # "change links" method, and from there we can do the unlink and
    # removal of the IFD (special-case)
    
    ae_config = init_resource      
    @ndev_res[:links] = get_cookie_links( ae_config ) || []    
    resource[:links] = []    
    @property_hash[:links] = true
    
  end  
 
  ### on_destroy is called by the 'change links' handler as a special
  ### case. that handler will immediately return once on_destroy is done
  
  def on_destroy( has_links, xml )
    
    par = xml.instance_variable_get(:@parent)         
    dot_ifd = par.at_xpath('ancestor::interfaces')      
    
    has_links.each do |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) do |dot|
      dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options) {
          dot.send( :'ieee-802.3ad', Netconf::JunosConfig::DELETE )
        }
      }
      end
    end
    
    Nokogiri::XML::Builder.with( dot_ifd ) do |dot|
      dot.interface( Netconf::JunosConfig::DELETE ) { 
        dot.name resource[:name]
      }
    end
    
  end

  ##### ------------------------------------------------------------
  #####              Utilities
  ##### ------------------------------------------------------------   

  def get_cookie_links( cfg )            
    cfg.xpath( "apply-macro[name = 'netdev_lag[:links]']/data/name" ).collect { |n|
      n.text
    }    
  end
  
  def set_cookie_links( cfg )
    cfg.send(:'apply-macro', Netconf::JunosConfig::REPLACE ) {
      cfg.name 'netdev_lag[:links]'
      resource[:links].each{ |ifd|
        cfg.data { cfg.name ifd }
      }
    }
  end
  
  ##### ------------------------------------------------------------
  #####              XML Resource Building
  ##### ------------------------------------------------------------   

  # -------------------------------------------    
  # PROPERTY: minimum_links
  # -------------------------------------------
  
  def xml_change_minimum_links( xml )
    if resource[:minimum_links] > 0
      xml.send(:'aggregated-ether-options') {
        xml.send( :'minimum-links', resource[:minimum_links] )
      }
    else
      xml.send(:'aggregated-ether-options') {
        xml.send(:'minimum-links', Netconf::JunosConfig::DELETE )
      }
    end
  end

  # -------------------------------------------    
  # PROPERTY: lacp
  # -------------------------------------------
  
  def xml_change_lacp( xml )
    if resource[:lacp] == :disabled
      xml.send(:'aggregated-ether-options') {
        xml.lacp( Netconf::JunosConfig::DELETE )
      }
    else
      xml.send(:'aggregated-ether-options') {
        xml.lacp {
          xml.send resource[:lacp]
        }
      }
    end
  end
  
  # -------------------------------------------    
  # PROPERTY: links
  # -------------------------------------------
  
  def xml_change_links( xml )    
    
    has = @ndev_res[:links] || []
    should = resource[:links] || []
    
    # --------------------------------------------------------------------
    # this is a special case where we're removing the entire LAG
    # we use an empty links list to trigger this action, see #destroy
    # method in the above code.
    # --------------------------------------------------------------------    
    
    if should.empty?
      on_destroy( has, xml )
      return
    end    
    
    set_cookie_links( xml )
    
    has = has.map(&:to_s)    
    should = should.map(&:to_s)    
    
    del = has - should
    add = should - has 
    
    par = xml.instance_variable_get(:@parent)         
    dot_ifd = par.at_xpath('ancestor::interfaces')

    add.each{ |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) {
      |dot| dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options.to_sym) {
          dot.send(:'ieee-802.3ad') {
            dot.bundle resource[:name]
          }
        }
    }}}  

    del.each{ |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) {
      |dot| dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options) {
          dot.send( :'ieee-802.3ad', Netconf::JunosConfig::DELETE )
        }
    }}}      
        
  end

end


