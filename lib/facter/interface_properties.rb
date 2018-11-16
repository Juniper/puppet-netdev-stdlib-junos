# Facts: speed_configurable, duplex_configurable
#
# Purpose:
#   Checks if speed and duplex properties of interfaces
#   are configurable dependening on the productmodel. 
#
# Test:
# # facter -p speed_configurable
# # false
#
# # facter -p duplex_configurable
# # false
#
# Caveats:
#

Facter.add(:speed_configurable) do 
   setcode do
     case Facter.value("productmodel")
      when /PTX10003-80C|PTX10003-160C/
         false
      when /QFX10003-80C|QFX10003-160C/
         false
      else
         true
     end
   end
end


Facter.add(:duplex_configurable) do 
   setcode do
     case Facter.value("productmodel")
      when /PTX10003-80C|PTX10003-160C/
         false
      when /QFX10003-80C|QFX10003-160C/
         false
      else
         true
     end
   end
end
