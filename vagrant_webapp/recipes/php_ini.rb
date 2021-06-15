service "httpd" do
  action :nothing
end

template "/etc/php.d/zzz.php-override.ini" do
  source "php-override.ini.erb"
  mode 0644
  if params[:cookbook]
    cookbook params[:cookbook]
  end

  notifies :restart, "service[httpd]", :delayed
end
