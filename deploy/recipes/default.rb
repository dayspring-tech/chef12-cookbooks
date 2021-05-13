# include_recipe 'dependencies'


opsworks_deploy_user do
  deploy_data node[:opsworks][:deploy_user]
end

