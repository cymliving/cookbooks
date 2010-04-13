#
# Cookbook Name:: zoneminder
# Recipe:: default
#
# Copyright 2010, Pangea Ventures, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

## include_recipe "apt"            # for apt-get update

include_recipe "apache2"
include_recipe "apache2::mod_rewrite"

include_recipe "mysql::client"

if node[:zoneminder][:db][:local_mysql] == "true"
  include_recipe "mysql::server"
  include_recipe "mysql::server_ec2" if node[:ec2] && false # alexg: TODO
end

Gem.clear_paths
require 'mysql'                 # for db check later on

# TODO: db and zm on same machine is currently working
execute "mysql-install-zm-privileges" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/zm/zm-grants.sql"
  action :nothing
end

template "/etc/zm/zm-grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :username => node[:zoneminder][:db][:username],
    :password => node[:zoneminder][:db][:password],
    :database => node[:zoneminder][:db][:database],
    :remotehost => 'localhost'
  )
  notifies :run, resources(:execute => "mysql-install-zm-privileges"), 
	:immediately
end

# save node data after writing the MYSQL root password, so that a
# failed chef-client run that gets this far doesn't cause an unknown
# password to get applied to the box without being saved in the node
# data.
ruby_block "save node data" do
  block do
    node.save
  end
  action :create
end

execute "create #{node[:zoneminder][:db][:database]} database" do
  command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:zoneminder][:db][:database]}"
  not_if do
    m = Mysql.new("localhost", "root", @node[:mysql][:server_root_password])
    m.list_dbs.include?(@node[:zoneminder][:db][:database])
  end
end

tmp_log_files = %w{ /tmp/zmdc.log /tmp/zmpkg.log }
var_log_files = %w{ zmdc.log zmpkg.log }.map{|fn| 
  node[:zoneminder][:path][:logs] +'/' + fn
}

tmp_log_files.each do |logfile|
  file logfile do
    owner "www-data"
    group "www-data"
    mode  0755
    action :create
    # not_if { File.exists? "/etc/zm/zm.conf" }
  end
end

var_log_files.each do |logfile|
  file logfile do
    owner "www-data"
    group "www-data"
    mode  0755
    action :nothing
  end
end

# TODO: runit services
service 'zoneminder' do
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

template "/etc/zm/zm.conf" do
  source 'zm.conf.erb'
  owner "www-data"
  group "www-data"
  mode "0600"
  variables :zoneminder => @node[:zoneminder]
  # a bug prevents zm from autocreating log files
  var_log_files.each do |log_file| 
    notifies :create, resources(:file => log_file), :immediately
  end
  notifies :reload, resources(:service => 'zoneminder')
end

package 'netpbm' do
  action :install
end

package 'zoneminder' do
  version "%s%s" % [node[:zoneminder][:version][:main],
                    node[:zoneminder][:version][:package_suffix]]
  action :install
  notifies :enable, resources(:service => 'zoneminder')
  # tmp_log_files.each do |log_file| 
  #   notifies :delete, resources(:file => log_file)
  # end
end

directory node[:zoneminder][:ssl][:cert_dir] do 
  owner "root"
  group "root"
  mode "700"
end

include_recipe "zoneminder::ssl" if 
  node[:zoneminder][:ssl][:enabled] == 'true'

web_app "zoneminder" do
  template "apache.conf.erb"
  server_name node[:zoneminder][:web][:server_name]
  server_aliases node[:zoneminder][:web][:server_aliases]

  ssl_listen_ip node[:ip_address]
  log_dir node[:zoneminder][:path][:logs]

  ssl_enabled node[:zoneminder][:ssl][:enabled] == 'true'

  ssl_cert_file node[:zoneminder][:ssl][:cert_dir] + '/' + 
    node[:zoneminder][:ssl][:local_cert_file]
end


# reconfigure zoneminder
#
# following SQL will show nondefault configs
#
## select name, value, defaultvalue
## from Config
## where
##    not (value = defaultvalue or
##         (value=1 and defaultvalue='yes') or
##         (value=0 and defaultvalue='no') )
##    and name not like 'ZM_EMAIL_%';

execute "mysql-install-zm-config" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} zm < /etc/zm/zm-config.sql"
  action :nothing
end

template "/etc/zm/zm-config.sql" do
  source 'zm-config.sql.erb'
  owner "root"
  group "root"
  mode "0600"
  variables(
            :zm_config => node[:zoneminder][:config][:values],
            :adminpw   => node[:zoneminder][:config][:adminpw],
            :zm_users  => search(:users, 'group:sysadmin'),
            :zm_admins => search(:users, 'group:zm_users')
            )
  notifies :run, resources(:execute => "mysql-install-zm-config")
end
