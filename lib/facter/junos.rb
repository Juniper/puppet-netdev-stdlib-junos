
  ### -----------------------------------------------------------------------------
  ### junos_personality
  ### -----------------------------------------------------------------------------

  Facter.add(:junos_personality) do
    setcode do
       case Facter.value("productmodel")
       when /^(ex)|(qfx)|(pvi-model)/i
          "JUNOS_switch"
       when /^srx(\d){4}/
          "JUNOS_SRX_HE"
       when /^srx(\d){3}/
          "JUNOS_SRX_branch"
       when /^junosv-firefly/
	  "JUNOS_SRX_branch"
       when /^mx|^vmx/
          "JUNOS_MX"
       when /PTX/
          "JUNOS_switch"
       end
    end
  end

  ### -----------------------------------------------------------------------------
  ### junos_ifd_style [ 'classis', 'switch' ]
  ### -----------------------------------------------------------------------------

  Facter.add(:junos_ifd_style) do
    confine :junos_personality => :JUNOS_switch
    setcode { "switch" }
  end

  Facter.add(:junos_ifd_style) do
    setcode { "classic" }
  end

  ### -----------------------------------------------------------------------------
  ### junos_switch_style [ 'vlan', 'bridge_domain', 'vlan_l2ng', 'none' ]
  ### -----------------------------------------------------------------------------

  Facter.add(:junos_switch_style) do
    confine :junos_personality => [:JUNOS_switch, :JUNOS_SRX_branch]  
    setcode do
      case Facter.value("productmodel")
      when /^(ex9)|(ex43)|(pvi-model)/
        "vlan_l2ng"
      when /^(qfx5)|(qfx3)/
        Facter.value("kernelmajversion")[0..3].to_f >= 13.2 ? "vlan_l2ng" : "vlan"
      else
        "vlan"
      end
    end
  end

  Facter.add(:junos_switch_style) do
    confine :junos_personality => [:JUNOS_MX, :JUNOS_SRX_HE]  
    setcode { "bridge_domain" }
  end
