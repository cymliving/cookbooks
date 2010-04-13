#
# Author:: Alexander Goldstein (<alexg@pangeaequity.com>)
# Cookbook Name:: zoneminder
# Attributes:: zoneminder
#
# Copyright 2009-2010, Opscode, Inc.
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

# DB Connection settings
set_unless[:zoneminder][:db][:local_mysql] = "true"

set_unless[:zoneminder][:db][:hostname] =
  node[:zoneminder][:db][:local_mysql] ? 'localhost' : 'zmdb'

set_unless[:zoneminder][:db][:database] = 'zm'
set_unless[:zoneminder][:db][:username] = 'zmuser'

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

set[:zoneminder][:db][:password] = 'zmpass'

# versions
set_unless[:zoneminder][:version][:main] = '1.24.1'
set_unless[:zoneminder][:version][:package_suffix] = '-1ubuntu2'

# paths
set_unless[:zoneminder][:path][:logs] = '/var/log/zm'

# config
set_unless[:zoneminder][:config][:adminpw] = secure_password
set_unless[:zoneminder][:config][:extra_sql] = nil

{
  :zm_opt_use_auth             => true,
  :zm_lang_default             => 'en_us',
  :zm_path_logs                => @node[:zoneminder][:path][:logs],
  :zm_opt_remote_cameras       => true,
  :zm_opt_netpbm               => true,
  :zm_web_title_prefix         => 'ZM',
  :zm_web_resize_console       => false,
  :zm_web_popup_on_alarm       => false,
  :zm_web_montage_max_cols     => 4,
  :zm_create_analysis_images   => true,
  :zm_check_for_updates        => false,
  :zm_web_h_video_maxfps       => 10,
  :zm_web_h_events_view        => 'timeline',
  :zm_web_m_events_view        => 'timeline',
  :zm_web_l_events_view        => 'timeline',
  :zm_dyn_show_donate_reminder => false
}.each_pair {|k,v| set_unless[:zoneminder][:config][:values][k] = v }

# alexg: this needs to be done using data bags
set_unless[:zoneminder][:config][:users] = {}

# web
set_unless[:zoneminder][:web][:server_name]    = fqdn
set_unless[:zoneminder][:web][:server_aliases] = 
  [ hostname, fqdn, fqdn.gsub(/^zoneminder/, 'zm') ].uniq

# ssl certs
set_unless[:zoneminder][:ssl][:enabled] = "true"
set_unless[:zoneminder][:ssl][:cert_dir] = '/etc/zm/certificates'
set_unless[:zoneminder][:ssl][:cert_file] = nil
set_unless[:zoneminder][:ssl][:local_cert_file] = nil


set_unless[:zoneminder][:ssl][:local_cert_file] =
  begin
    cert_file = zoneminder[:ssl][:cert_file] 
    cert_file && File.basename(cert_file) || "#{fqdn}.pem"
  end

set_unless[:zoneminder][:ssl][:req]  = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/" +
  "CN=#{fqdn}/emailAddress=#{apache[:contract]}"
