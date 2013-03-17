=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_netdev_log.rb
* Version        : 2012-11-09
* Platform       : All Junos
* Description    : 
*
*    This file contains the code responsible for reporting
*    logs associated with the Junos Netdev module
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

module NetdevJunos
  module Log
    class << self   
      def err( msg, args = {} )
        Puppet::Util::Log.create({:source => :JUNOS, 
          :level => :err, 
          :message => msg }.merge( args ))        
      end      
      def notice( msg, args = {} )
        Puppet::Util::Log.create({:source => :JUNOS, 
          :level => :notice, 
          :message => msg }.merge( args ))        
      end      
      def info( msg, args = {} )
        Puppet::Util::Log.create({:source => :JUNOS, 
          :level => :info, 
          :message => msg }.merge( args ))        
      end
      def debug( msg, args = {} )
        Puppet::Util::Log.create({:source => :JUNOS, 
          :level => :debug, 
          :message => msg }.merge( args ))        
      end      
    end
  end
end
