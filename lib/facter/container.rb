# Fact: container
#
# Purpose:
#   Returns the container type.
#
# Test:
# # facter -p container
# docker
#
# Caveats:
#

Facter.add(:container) do
  setcode do
    query = ":/docker"
    arr = File.readlines("/proc/1/cgroup").grep /#{query}/i
    if arr.any?
       "docker"
    else
       false
    end
  end
end