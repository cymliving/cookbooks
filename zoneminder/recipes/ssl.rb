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

# enable ssl so correct zonemidner.conf is generated for apache
set[:zoneminder][:ssl][:enabled] = "true" unless
  node[:zoneminder][:ssl][:enabled] == 'true'

include_recipe "apache2::mod_ssl"

cert_dir        = node[:zoneminder][:ssl][:cert_dir]
local_cert_file = node[:zoneminder][:ssl][:local_cert_file]
local_cert_base = local_cert_file.gsub(/\.pem$/, '')


bash "Create SSL Certificates" do
  cwd "#{cert_dir}"
  code <<-EOH
  umask 077
  openssl genrsa 2048 > #{local_cert_base}.key
  openssl req -subj "#{node[:zoneminder][:ssl][:req]}" -new -x509 -nodes -sha1 -days 3650 -key #{local_cert_base}.key > #{local_cert_base}.crt
  cat #{local_cert_base}.key #{local_cert_base}.crt > #{local_cert_file}
  EOH
  not_if { File.exists?("#{cert_dir}/#{local_cert_file}") }

  # alexg: should be not_if but cleaner to separate from check above
  only_if { ! node[:zoneminder][:ssl][:cert_file] }
end

remote_file "#{cert_dir}/#{local_cert_file}" do
  source node[:zoneminder][:ssl][:cert_file]

  mode 0755
  owner "root"
  group "root"

  only_if { node[:zoneminder][:ssl][:cert_file] }
end


