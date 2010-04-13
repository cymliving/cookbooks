maintainer       "Alexander Goldstein"
maintainer_email "alexg@pangeaequity.com"
license          "Apache 2.0"
description      "Installs/Configures zoneminder"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1"

# pull in apache2
depends "apache2"
depends "mysql"
depends "openssl"
## depends "apt"

%w{ debian ubuntu }.each do |os|
  supports os
end

attribute "zoneminder/version/main",
   :display_name => "ZM version to install",
   :description  => "ZM version to install",
   :default => "1.24.1"

attribute "zoneminder/version/package_suffix",
   :display_name => "Package version suffix",
   :description  => "Pacakge version suffix",
   :default => "1ubuntu2"

attribute "zoneminder/db/local_mysql",
   :display_name => "ZM will install mysql locally",
   :description  => "Should ZM recipe install mysql locally",
   :default => "yes"

attribute "zoneminder/db/hostname",
   :display_name => "ZM mysql hostname",
   :description  => "ZM mysql hostname",
   :default => 'install_mysql ? localhost : zmdb'

attribute "zoneminder/db/database",
   :display_name => "ZM mysql db name",
   :description  => "ZM mysql db name",
   :default => 'zm'

attribute "zoneminder/db/user",
   :display_name => "ZM mysql db username",
   :description  => "ZM mysql db username",
   :default => 'zmuser'

attribute "zoneminder/db/password",
   :display_name => "ZM mysql db password",
   :description  => "ZM mysql db password",
   :default => 'zm default (breaks if changed)'

attribute "zoneminder/path/logs",
   :display_name => "ZM logfile directory",
   :description  => "ZM logfile directory",
   :default => '/var/log/zm'

attribute "zoneminder/config/adminpw",
   :display_name => "ZM admin password",
   :description  => "ZM admin password",
   :default => 'randomly generated'

attribute "zoneminder/config/extra_sql",
   :display_name => "Extra SQL to be executed by chef to configure ZM",
   :description  => "Extra SQL file tempalte to be executed by chef to setup",
   :default => 'nothing'

attribute "zoneminder/config/values",
   :display_name => "Values for ZM config variables to set",
   :description  => "Values for ZM config variables to set (upcased if needed)",
   :type => 'hash',
   :default => 'some reasonable values (see attributes)'

attribute "zoneminder/ssl/enabled",
   :display_name => "Enable SSL apache2 for ZM",
   :description  => "Enable SSL apache2 for ZM",
   :default => 'true'

attribute "zoneminder/ssl/cert_dir",
   :display_name => "Directory to store and find SSL certificates",
   :description  => "Directory to store and find SSL certificates",
   :default => '/etc/zm/certificates'

attribute "zoneminder/ssl/cert_file",
   :display_name => "SSL certificate to transfer to server",
   :description  => "SSL certificate to transfer to server.  pem file with key and cert combined. ",
   :default => 'create locally'

attribute "zoneminder/ssl/local_cert_file",
   :display_name => "Local name of SSL certificate",
   :description  => "Local nmae of SSL certificate in cert_dir.",
   :default => 'either basename(cert_file) or server_fqdn.pem'

