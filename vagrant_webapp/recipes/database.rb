package "mysql" do
  source "https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm"
  action :install
  provider Chef::Provider::Package::Rpm
end

package "mysql-community-server" do
  action :install
end

service "mysqld" do
  action :start
end

template "/etc/my.cnf" do
  source "my.cnf.erb"
  mode 0644
  notifies :restart, 'service[mysqld]', :immediate
end

script "change mysql password" do
  interpreter "bash"
  user "root"
  code <<-EOH
  password=$(cat /var/log/mysqld.log | grep "A temporary password is generated for" | tail -1 | sed -n 's/.*root@localhost: //p')
  newPassword="#{node['mysql']['server_root_password']}"
  # resetting temporary password
  mysql --connect-expired-password -uroot -p$password -Bse "ALTER USER 'root'@'localhost' IDENTIFIED BY '$newPassword';"  
  EOH
  not_if "mysqladmin -u root -p#{node['mysql']['server_root_password']} version"
end

if node['vagrant']
  node[:deploy].each do |application, deploy|
    mysql_database deploy[:database][:database] do
      host '127.0.0.1'
      user 'root'
      password node['mysql']['server_root_password']
      action :create
    end

    mysql_user deploy[:database][:username] do
      ctrl_host '127.0.0.1'
      ctrl_user 'root'
      ctrl_password node['mysql']['server_root_password']

      password      deploy[:database][:password]
      action        :create
    end

    mysql_user deploy[:database][:username] do
      ctrl_host '127.0.0.1'
      ctrl_user 'root'
      ctrl_password node['mysql']['server_root_password']

      password      deploy[:database][:password]
      database_name deploy[:database][:database]
      host          deploy[:database][:host]
      privileges    [:all]
      action        :grant
    end
    
  end
end


# mysql_service 'default' do 
#   version '5.7'
#   package_name 'mysql-community-server'
#   bind_address '0.0.0.0'
#   port '3306'
#   data_dir '/data'
#   initial_root_password node['mysql']['server_root_password']
#   action [:create, :start]
# end

