# CHANGELOG

### 2013-02-15
* Initial release of code, corresponding to Juniper Early Adopter release 0.8B1.1
* Support for the following Juniper Platforms and software releases
  * EX4200, EX4550 - Junos 12.2R3.7
  * QFX3500 - Junos 12.2X50-D30.4
* Requires Puppet for Junos OS software package to be installed on Junos OS device.  
  For documentation, refer to: [Puppet for Junos OS](http://www.juniper.net/techpubs/en_US/release-independent/junos-puppet/information-products/pathway-pages/index.html)
  
### 2013-03-03
* Enhancements to support Juniper MX5 ... MX960 products

### 2013-03-15
* Bugfixes, and support for broader Junos products

### 2013-03-19
* Updated code to support 'feature' controls, requires netdevops/netdev_stdlib

### 2013-03-29
* Bugfixes, ready for release 1.0.0

### 2014-09-24
* Bugfixes, upgrade version to 1.0.2

### 2015-05-05
* Add support for new JUNOS resource type "netdev_group", upgrade to version 2.0.0
  
### 2015-06-30
* Add support for defined type 'apply_group' and minor bug fixes, upgrade to version 2.0.1-beta

### 2016-03-17
* Bug fix: 
  - Issue #17 Puppet: Error message while executing XML format ERB template
  - Issue #20 Issue while configuring LAG on 15.2 junos-x image
* Fixed puppet lint issues
* Upgrade to a stable version 2.0.2

### 2019-02-27
* Bug fix:
  - Issue with netdev_lag creation and deletion - interfaces arriving as array
    entries changed to look like normal interfaces to netconf.
* Upgrade to 2.0.5

### 2020-07-03
* Bug fix:
   - Enabled case-insensitive comparisons for QFX product models.
* Upgrade to 2.0.6
