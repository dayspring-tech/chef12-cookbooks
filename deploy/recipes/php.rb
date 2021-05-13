#
# Cookbook Name:: deploy
# Recipe:: php
#

include_recipe 'deploy'
# include_recipe "mod_php5_apache2"
# include_recipe "mod_php5_apache2::php"

Chef::Log.info("starting deploy::php")
Chef::Log.info(node)


search("aws_opsworks_app").each do |app|
  # all chef 12 apps are "other"
  # if deploy[:application_type] != 'php'
  #   Chef::Log.debug("Skipping deploy::php application #{application} as it is not an PHP app")
  #   next
  # end
  
  Chef::Log.info("starting deploy::php application #{app['shortname']}")

  opsworks_deploy_dir do
    user node[:opsworks][:deploy_user][:user]
    group node[:opsworks][:deploy_user][:group]
    path "/srv/www/#{app['shortname']}"
  end

  opsworks_deploy do
    deploy_data app
    app app['shortname']
    deploy_to "/srv/www/#{app['shortname']}"
  end

  directory "#{node[:apache][:dir]}/sites-available/#{app[:shortname]}.conf.d"

  web_app app[:shortname] do
    docroot "/srv/www/#{app['shortname']}/current/#{app[:attributes][:document_root]}"
    server_name app[:domains].first
    unless app[:domains][1, app[:domains].size].empty?
      server_aliases app[:domains][1, app[:domains].size]
    end
    app app
    rewrite_config "#{node[:apache][:dir]}/sites-available/#{app[:shortname]}.conf.d/rewrite"
    local_config "#{node[:apache][:dir]}/sites-available/#{app[:shortname]}.conf.d/local"
    environment app[:environment]
    ssl_certificate_ca app[:ssl_configuration][:chain]
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.crt" do
    mode 0600
    source 'ssl.key.erb'
    variables :key => app[:ssl_configuration][:certificate]
    notifies :restart, "service[apache2]"
    only_if do
      app[:enable_ssl]
    end
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.key" do
    mode 0600
    source 'ssl.key.erb'
    variables :key => app[:ssl_configuration][:private_key]
    notifies :restart, "service[apache2]"
    only_if do
      app[:enable_ssl]
    end
  end

  template "#{node[:apache][:dir]}/ssl/#{app[:domains].first}.ca" do
    mode 0600
    source 'ssl.key.erb'
    variables :key => app[:ssl_configuration][:chain]
    notifies :restart, "service[apache2]"
    only_if do
      app[:enable_ssl] && app[:ssl_configuration][:chain]
    end
  end

  # move away default virtual host so that the new app becomes the default virtual host
  if platform?('ubuntu') && node[:platform_version] == '14.04'
    source_default_site_config = "#{node[:apache][:dir]}/sites-enabled/000-default.conf"
    target_default_site_config = "#{node[:apache][:dir]}/sites-enabled/zzz-default.conf"
  else
    source_default_site_config = "#{node[:apache][:dir]}/sites-enabled/000-default"
    target_default_site_config = "#{node[:apache][:dir]}/sites-enabled/zzz-default"
  end
  execute 'mv away default virtual host' do
    action :run
    command "mv #{source_default_site_config} #{target_default_site_config}"
    notifies :reload, "service[apache2]", :delayed
    only_if do
      ::File.exists?(source_default_site_config)
    end
  end  
end

