define :opsworks_deploy do
  application = params[:app]
  deploy = params[:deploy_data]
  deploy_to = params[:deploy_to]

  node.set[:opsworks][:deploy_user][:home] = "/home/#{node[:opsworks][:deploy_user][:user]}"
  deploy_user = node[:opsworks][:deploy_user]

  directory "#{deploy_to}" do
    group deploy_user[:group]
    owner deploy_user[:user]
    mode "0775"
    action :create
    recursive true
  end

  node.set[:deploy][application] = deploy
  node.set[:deploy][application][:deploy_to] = deploy_to
  node.set[:deploy][application][:user] = deploy_user[:user]
  node.set[:deploy][application][:group] = deploy_user[:group]

  if deploy[:app_source]
    ensure_scm_package_installed(deploy[:app_source][:type])

    prepare_git_checkouts(
      :user => deploy_user[:user],
      :group => deploy_user[:group],
      :home => deploy_user[:home],
      :ssh_key => deploy[:app_source][:ssh_key]
    ) if deploy[:app_source][:type].to_s == 'git'

    if deploy[:app_source][:type].to_s == 'archive'
      repository = prepare_archive_checkouts(deploy[:app_source])
      node.set[:deploy][application][:app_source] = {
        :type => 'git',
        :url => repository
      }
    elsif deploy[:app_source][:type].to_s == 's3'
      repository = prepare_s3_checkouts(deploy[:app_source])
      node.set[:deploy][application][:app_source] = {
        :type => 'git',
        :url => repository
      }
    end
  end


  deploy = node[:deploy][application]
  Chef::Log.info(deploy)

  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
    only_if do
      deploy[:delete_cached_copy]
    end
  end

  ruby_block "change HOME to #{deploy_user[:home]} for source checkout" do
    block do
      ENV['HOME'] = "#{deploy_user[:home]}"
    end
  end

  # setup deployment & checkout
  if deploy[:app_source] && deploy[:app_source][:type] != 'other'
    Chef::Log.debug("Checking out source code of application #{application} with type #{deploy[:application_type]}")
    deploy deploy[:deploy_to] do
      provider Chef::Provider::Deploy.const_get(node[:opsworks][:deploy_chef_provider])
      keep_releases node[:opsworks][:deploy_keep_releases]
      repository deploy[:app_source][:url]
      user deploy_user[:user]
      group deploy_user[:group]
      revision deploy[:app_source][:revision]
      environment deploy[:environment].to_hash

      case deploy[:app_source][:type].to_s
      when 'git'
        scm_provider :git
        # enable_submodules deploy[:enable_submodules]
        # shallow_clone deploy[:shallow_clone]
      else
        raise "unsupported SCM type #{deploy[:app_source][:type].inspect}"
      end

      before_migrate do
        link_tempfiles_to_current_release

        # can't search by a value that includes colons
        escapedRdsArn = deploy[:data_sources][0][:arn]&.gsub(":", "\\:")
        rds = search("aws_opsworks_rds_db_instance", "rds_db_instance_arn:#{escapedRdsArn}").first
        # rds = search("aws_opsworks_rds_db_instance").first

        template "#{node[:deploy][application][:deploy_to]}/shared/config/opsworks.php" do
          source 'opsworks.php.erb'
          mode '0660'
          owner node[:deploy][application][:user]
          group node[:deploy][application][:group]
          variables(
            :database => {
              :host => rds[:address],
              :database => deploy[:data_sources][0][:database_name],
              :port => rds[:port],
              :username => rds[:db_user],
              :password => rds[:db_password],
              :reconnect => true,
              :data_source_provider => 'rds',
              :type => rds[:engine]
            },
            :memcached => {
              :host => nil,
              :port => 11211
            }
          )
          only_if do
            File.exists?("#{node[:deploy][application][:deploy_to]}/shared/config")
          end
        end        

        # run user provided callback file
        run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
      end
    end

    if deploy[:app_source][:url].start_with?(Dir.tmpdir)
      directory "#{node[:deploy][application][:deploy_to]}/current/.git" do
        recursive true
        action :delete
      end
    end
  end

  ruby_block "change HOME back to /root after source checkout" do
    block do
      ENV['HOME'] = "/root"
    end
  end


  bash "Enable selinux var_log_t target for application log files" do
    dir_path_log = "#{deploy[:deploy_to]}/shared/log"
    context = "var_log_t"

    user "root"
    code <<-EOH
    semanage fcontext --add --type #{context} "#{dir_path_log}(/.*)?" && restorecon -rv "#{dir_path_log}"
    EOH
    not_if { OpsWorks::ShellOut.shellout("/usr/sbin/semanage fcontext -l") =~ /^#{Regexp.escape("#{dir_path_log}(/.*)?")}\s.*\ssystem_u:object_r:#{context}:s0/ }
    only_if { platform_family?("rhel") && ::File.exist?("/usr/sbin/getenforce") && OpsWorks::ShellOut.shellout("/usr/sbin/getenforce").strip == "Enforcing" }
  end

  template "/etc/logrotate.d/opsworks_app_#{application}" do
    backup false
    source "logrotate.erb"
    cookbook 'deploy'
    owner "root"
    group "root"
    mode 0644
    variables( :log_dirs => ["#{deploy[:deploy_to]}/shared/log" ] )
  end
end
