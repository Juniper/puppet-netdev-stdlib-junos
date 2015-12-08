=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_l2_interface_l2ng.rb
* Version        : 2013-03-12
* Platform       : EX-L2NG
* Description    : 
*
*    This file implements the network_trunk type for
*    the EX/MX products supporting the L2NG style.  
*
* Copyright (c) 2013  Juniper Networks. All Rights Reserved.
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

class Puppet::Provider::Junos::L2InterfaceL2NG < Puppet::Provider::Junos 

  ### ---------------------------------------------------------------  
  ### triggered from Provider #exists?
  ### ---------------------------------------------------------------  
  
  def netdev_res_exists?
     
    resource[:description] ||= default_description
    resource[:tagged_vlans] = resource[:tagged_vlans].to_a || []     
    resource[:untagged_vlan] ||= ''     # if not set in manifest, it is nil   
    resource[:vlan_tagging] = :enable unless resource[:tagged_vlans].empty? 
    
    self.class.initcvar_for_untagged_vlan      
    self.class.initcvar_vlanxrefs( resource )    
    
    return false unless init_ndev_res

    @ndev_res[:description] = ''
    @ndev_res[:vlan_tagging] = :disable
    @ndev_res[:untagged_vlan] = ''
    @ndev_res[:tagged_vlans] = []         
    
    @ndev_res[:description] = @ifl_config.xpath('description').text.chomp    
    fam_eth_cfg = @ifl_config.xpath('family/ethernet-switching')      
    
    return false if fam_eth_cfg.empty?
    
    netdev_retrieve_fam_eth_info( fam_eth_cfg )
    
    return true
  end   
  
  ### ---------------------------------------------------------------
  ### called from #netdev_exists?
  ### ---------------------------------------------------------------  
  
  def init_ndev_res
    
    @ndev_res ||= NetdevJunos::Resource.new( self, "interfaces", "interface" )
     
    ndev_config = @ndev_res.getconfig    
    @ifd_config = ndev_config.xpath('//interface')[0]
    return false unless @ifd_config
    
    @ifl_config = @ifd_config.xpath('unit')[0]    
    return false unless @ifl_config
    
    @ndev_res.set_active_state( @ifl_config )      
    return true
  end
  
  def default_description
    "Puppet created network_trunk: #{resource[:name]}"
  end
  
  def netdev_retrieve_fam_eth_info( fam_eth_cfg )
    
    @ndev_res[:vlan_tagging] = fam_eth_cfg.xpath('interface-mode').text.chomp == 'trunk' ? :enable : :disable
    
    # --- access port      
    
    if @ndev_res[:vlan_tagging] == :disable
      @ndev_res[:untagged_vlan] = fam_eth_cfg.xpath('vlan/members').text.chomp || ''
      return
    end
        
    # --- trunk port       
    
    native_vlan_id = @ifd_config.xpath('native-vlan-id').text.chomp;
    @ndev_res[:untagged_vlan] = native_vlan_id.empty? ? '' : self.class.vlan_tags_to_names( native_vlan_id ) 
    
    @ndev_res[:tagged_vlans] = fam_eth_cfg.xpath('vlan/members').collect { |v| v.text.chomp }
  end
  
  def is_trunk?
    @ndev_res[:vlan_tagging] == :enable
  end
  
  def should_trunk?
    resource[:vlan_tagging] == :enable
  end
  
  def mode_changed?
    @ndev_res[:name].nil? or (resource[:vlan_tagging] != @ndev_res[:vlan_tagging])
  end
    
  ### --------------------------------------------------------------------
  ### Routines that work to translate vlan-names to vlan-tagid
  ### --------------------------------------------------------------------
    
  class << self
    
    def initcvar_vlanxrefs( resource )
      
      @@rpc ||= Puppet::Provider::Junos.netdev.netconf.rpc
      @@catalog ||= resource.catalog
      @@catalog_network_vlan ||= @@catalog.resources.select{ |r| r.type == :network_vlan }
            
      @@vlan_name_hash ||= {}
      @@vlan_tag_hash ||= {}
      @@vlan_rewrite ||= {}
      
      # note: resource[:tagged_vlans] is stored as Array-of-Arrays.  ugh ...
      # so need to grab the .to_s for just the string name...
      
      all_vlan_names = resource[:tagged_vlans].clone      
      all_vlan_names << resource[:untagged_vlan] unless resource[:untagged_vlan].empty?            
      all_vlan_names.each{ |vlan_name| vlanxrefs_addbyname( vlan_name.to_s ) }
      
      # load the table of currently used VLANs from the device      
      vlanxrefs_from_junos( resource )
      
    end
    
    def vlanxrefs_from_junos( resource )
            
      vlan_if_info = @@rpc.get_vlan_information(:interface => resource[:name] + ".0")
      
      vlan_names = vlan_if_info.xpath('//l2ifbd-vlan-name')
      vlan_names.each do |name|
        vlan_name = name.text
                
        vlan_info = @@rpc.get_vlan_information( :vlan_name => vlan_name, :brief => true )
        dev_vlan_id = vlan_info.xpath('//l2ng-l2rtb-vlan-tag').text.chomp      
        
        if pp_vlan_id = @@vlan_name_hash[vlan_name]
          # then Puppet already knows about this vlan, need to see if the vlan-id
          # has changed as a result of a network_vlan update
          if dev_vlan_id != pp_vlan_id
            @@vlan_name_hash['~' + vlan_name] = pp_vlan_id
          end
        else
          # Puppet didn't know abou this vlan, so add it to the managed list ...
          @@vlan_name_hash[vlan_name] = dev_vlan_id
        end
        @@vlan_tag_hash[dev_vlan_id] = vlan_name        
      end # each: bd_name      
    end
    
    def vlanxrefs_addbyname( vlan_name )
      return if @@vlan_name_hash[vlan_name]              

      # let's see if Puppet knows about this vlan_name ...
      # we snarf the tilde (~) in case this is a triggered vlan_name
      # change; and the vlan_names in the catalog don't have a tilde.  Yo!
      
      if vlan_res = @@catalog.resource( :network_vlan, vlan_name.sub( '~',''))
        vlan_id = vlan_res[:vlan_id]          
        @@vlan_name_hash[vlan_name] = vlan_id
        @@vlan_tag_hash[vlan_id] = vlan_name
        return
      end
      
      # Pupept doesn't know, so we need to go to the config 
      # and retrieve what we need ...
      
      vlan_cfg = @@rpc.get_configuration{|cfg|
        cfg.vlans {
          cfg.vlan { cfg.name vlan_name
            cfg.send(:'vlan-id')
          }
      }}
      
      vlan_id = vlan_cfg.xpath('//vlan-id').text.chomp
      if vlan_id.empty?
        Kernel.raise Puppet::DevError, "requested VLAN #{vlan_name} does not exist!"
        return
      end
      
      @@vlan_name_hash[vlan_name] = vlan_id
      @@vlan_tag_hash[vlan_id] = vlan_name        
      
    end
    
    def vlanxrefs_addbytag( switch_name, tag_id )   # returns the vlan name
      
      # resource[:vlan_id] is a Fixnum, and tag_id is String. So
      # convert to Fixnum now for comparison ...
      tag_id_i = tag_id.to_i            
      
      p_ndev_vlan = @@catalog_network_vlan.select{ |v| v[:vlan_id].to_i == tag_id_i }[0]
      if p_ndev_vlan
        vlan_name = p_ndev_vlan[:name]
        @@vlan_name_hash[vlan_name] = tag_id
        @@vlan_tag_hash[tag_id] = vlan_name
        vlan_name
      else             
        Kernel.raise Puppet::DevError, "Unknown VLAN, tag-id: #{tag_id} does not exist!"      
      end
    end
    
    def vlan_tags_to_names( tagid_a )      
      if tagid_a.class == Array
        tagid_a.collect{ |tag_id| @@vlan_tag_hash[tag_id] || vlanxrefs_addbytag( 'default-switch', tag_id ) }
      else
        @@vlan_tag_hash[tagid_a] || vlanxrefs_addbytag( 'default-switch', tagid_a )
      end
    end
    
    def vlan_names_to_tags( names_a )
      if names_a.class == Array
        tags_a = names_a.collect{ |name| @@vlan_name_hash[name] }
      else
        @@vlan_name_hash[names_a]
      end
    end    
  end
  
  ##### ------------------------------------------------------------
  #####              XML Resource Building
  ##### ------------------------------------------------------------   
  
  # override default 'edit' method to place 'dot' inside
  # the family bridge stanza
  
  def netdev_resxml_edit( xml )
    xml.unit {
      xml.name '0' 
      xml.family { 
        xml.send(:'ethernet-switching') {
          return xml
        }
      }
    }
  end
  
  ###
  ### :description
  ###
  
  def xml_change_description( xml )    
    par = xml.instance_variable_get(:@parent)        
    Nokogiri::XML::Builder.with( par.at_xpath( 'ancestor::unit' )) do |dot|
      dot.description resource[:description]
    end    
  end
  
  ####
  #### :vlan_tagging
  ####
  
  def xml_change_vlan_tagging( xml )
    
    port_mode = should_trunk? ? 'trunk' : 'access'
    xml.send :"interface-mode", port_mode
    
    # when the vlan_tagging value changes then this method
    # will trigger updates to the untagged_vlan and tagged_vlans
    # resource values as well.
    
    upd_untagged_vlan( xml )
    upd_tagged_vlans( xml )
    
  end
  
  ### ---------------------------------------------------------------
  ### XML:tagged_vlans
  ### ---------------------------------------------------------------  
  
  def xml_change_tagged_vlans( xml )  
    return if mode_changed?  
    upd_tagged_vlans( xml )
  end
  
  def upd_tagged_vlans( xml )
    
    return unless should_trunk?
    
    should = resource[:tagged_vlans] || []
    has = @ndev_res[:tagged_vlans] || []    
      
    has = has.map(&:to_s)    
    should = should.map(&:to_s)        
    
    del = has - should
    add = should - has
    
    if add or del
      Puppet.debug "#{resource[:name]}: Adding VLANS: [#{add.join(',')}]" unless add.empty?
      Puppet.debug "#{resource[:name]}: Deleting VLANS: [#{del.join(',')}]" unless del.empty? 
      xml.vlan {
        del.each{|v| xml.members v, Netconf::JunosConfig::DELETE }
        add.each{|v| xml.members v }
      }
    end
    
  end  
  
  ### ---------------------------------------------------------------
  ### XML:untagged_vlan
  ### ---------------------------------------------------------------  
  
  def xml_change_untagged_vlan( xml )           
    return if mode_changed?         
    upd_untagged_vlan( xml )
  end  
  
  def upd_untagged_vlan( xml )
    self.class.change_untagged_vlan( self, xml )
  end  
  
  class << self
    
    # creating some class definitions ...
    # this is a bit complicated because we need to handle port-mode
    # change transitions; basically dealing with the fact that
    # trunk ports use 'native-vlan-id' and access ports have a
    # vlan member definition; i.e. they don't use native-vlan-id, ugh.
    # Rather than doing all this logic as if/then/else statements,
    # I've opted to using a proc jump-table technique.  Lessons
    # learned from lots of embedded systems programming :-)    
    
    def initcvar_jmptbl_untagged_vlan
      
      # auto-hash table
      hash = Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
      
      # ------------------------------------------------------------------
      # -   jump table for handling various untagged vlan change use-cases      
      # ------------------------------------------------------------------      
      # There are three criteria for selection:  
      # | is_trunk | will_trunk | no_untg |
      # ------------------------------------------------------------------
      # - will not have untagged vlan 
      hash[false][false][true] = self.method(:ac_ac_nountg)
      hash[false][true][true] = self.method(:ac_tr_nountg)
      hash[true][false][true] = self.method(:tr_ac_nountg)
      hash[true][true][true] = self.method(:tr_tr_nountg)
      # - will have untagged vlan 
      hash[false][false][false] = self.method(:ac_ac_untg)
      hash[false][true][false] = self.method(:ac_tr_untg)
      hash[true][false][false] = self.method(:tr_ac_untg)
      hash[true][true][false] = self.method(:tr_tr_untg)
      
      hash
    end
    
    ### initialize the jump table once as a class variable
    ### this is called from #init_resource
    
    def initcvar_for_untagged_vlan    
      @@untgv_jmptbl ||= initcvar_jmptbl_untagged_vlan
    end
    
    ### invoke the correct method from the jump table
    ### based on the three criteria to select the action
    
    def change_untagged_vlan( this, xml )
      proc = @@untgv_jmptbl[this.is_trunk?][this.should_trunk?][this.resource[:untagged_vlan].empty?]
      proc.call( this, xml )
    end
    
    ### -------------------------------------------------------------
    ### The following are all the change transition functions for
    ### each of the use-cases
    ### -------------------------------------------------------------
    
    def ac_ac_nountg( this, xml )
      NetdevJunos::Log.debug "ac_ac_nountg"                        
      # @@@ a port *MUST* be assigned to a vlan in access mode on MX.
      # @@@ generate an error!      
      Kernel.raise Puppet::DevError, "untagged_vlan missing, port must be assigned to a VLAN"      
    end
    
    def ac_tr_nountg( this, xml )      
      NetdevJunos::Log.debug "ac_tr_nountg"                             
      ## no action needed; handled already
    end
    
    def tr_ac_nountg( this, xml )
      NetdevJunos::Log.debug "tr_ac_nountg"     
      # @@@ a port *MUST* be assigned to a vlan in access mode on MX.
      # @@@ generate an error!      
      Kernel.raise Puppet::DevError, "untagged_vlan missing, port must be assigned to a VLAN"
    end
    
    def tr_tr_nountg( this, xml )
      NetdevJunos::Log.debug "tr_tr_nountg"                  
      set_native_vlan_id( this, xml, :delete )
    end
    
    def ac_ac_untg( this, xml )
      NetdevJunos::Log.debug "ac_ac_untg"                  
      set_vlan_id( this, xml )
    end
    
    def ac_tr_untg( this, xml )      
      NetdevJunos::Log.debug "ac_tr_untg"            
      set_vlan_id( this, xml, :delete ) if this.ndev_res[:untagged_vlan]
      set_native_vlan_id( this, xml )
    end
    
    def tr_ac_untg( this, xml )
      NetdevJunos::Log.debug "tr_ac_untg"      
      set_native_vlan_id( this, xml, :delete )
      set_vlan_id( this, xml )      
    end
    
    def tr_tr_untg( this, xml )
      NetdevJunos::Log.debug "tr_tr_untg"
      set_native_vlan_id( this, xml )
    end

    ### -------------------------------------------------------------
    ### helper methods, re-usable for each of the transitions
    ### -------------------------------------------------------------
    
    def set_vlan_id( this, xml, delete = :no )
      xml.vlan( Netconf::JunosConfig::REPLACE ) {
        if delete == :delete
          xml.members this.resource[:untagged_vlan], Netconf::JunosConfig::DELETE
        else
          xml.members this.resource[:untagged_vlan]
        end
      }
    end
        
    def set_native_vlan_id( this, xml, delete = :no )
      par = xml.instance_variable_get(:@parent)     
      vlan_id = vlan_names_to_tags( this.resource[:untagged_vlan] )
      Nokogiri::XML::Builder.with( par.at_xpath( 'ancestor::interface' )) do |dot|
        if delete == :delete
          dot.send( :'native-vlan-id', Netconf::JunosConfig::DELETE )
        else
          dot.send( :'native-vlan-id', vlan_id )    
        end
      end    
    end 
    
  end # class methods for changing untagged_vlan
  
end


