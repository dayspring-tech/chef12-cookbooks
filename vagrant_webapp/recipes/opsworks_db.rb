node[:deploy].each do |application, deploy|

	if node['vagrant']

    directory "#{node[:deploy][application][:deploy_to]}/shared" do
      owner node[:deploy][application][:user]
      group node[:deploy][application][:group]
      mode "0755"
      action :create
    end

    directory "#{node[:deploy][application][:deploy_to]}/shared/config" do
      owner node[:deploy][application][:user]
      group node[:deploy][application][:group]
      mode "0755"
      action :create
    end

    template "#{node[:deploy][application][:deploy_to]}/shared/config/opsworks.php" do
      source 'opsworks.php.erb'
      mode '0660'
      owner node[:deploy][application][:user]
      group node[:deploy][application][:group]
      variables(
        :database => node[:deploy][application][:database]
      )
      only_if do
        File.exists?("#{node[:deploy][application][:deploy_to]}/shared/config")
      end
    end

  end
end
