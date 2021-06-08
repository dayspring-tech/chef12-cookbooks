service "crond" do
    action :nothing
end

service "rsyslog" do
    action :nothing
end

script "set_system_timezone" do
    interpreter "bash"
    user "root"
    code <<-EOH
        cp /usr/share/zoneinfo/#{node[:system][:timezone]} /etc/localtime
    EOH
    notifies :restart, "service[crond]", :immediately
    notifies :restart, "service[rsyslog]", :immediately
    only_if { (Time.new).zone == 'UTC' && node[:system][:timezone] != 'UTC' }
end
