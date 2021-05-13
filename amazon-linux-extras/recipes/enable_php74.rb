execute "enable php7.4" do
    command "amazon-linux-extras enable php7.4"
    user "root"
    action :run
end
