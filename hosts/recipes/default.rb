instance = search("aws_opsworks_instance", "self:true").first

template "/etc/hosts" do
  source "hosts.erb"
  mode "0644"
  variables(
    :localhost_name => instance["hostname"],
    :nodes => generate_hosts_entries
  )
end
