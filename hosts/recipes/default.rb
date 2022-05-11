instance = search("aws_opsworks_instance", "self:true").first

Chef::Log.info(search("aws_opsworks_instance"))
Chef::Log.info(generate_hosts_entries)

template "/etc/hosts" do
  source "hosts.erb"
  mode "0644"
  variables(
    :localhost_name => instance["hostname"],
    :nodes => generate_hosts_entries,
    :custom_nodes => node["custom_hosts"]
  )
end
