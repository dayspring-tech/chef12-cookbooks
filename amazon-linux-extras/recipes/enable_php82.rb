execute "enable php8.2" do
    command "amazon-linux-extras enable php8.2"
    user "root"
    action :run
end
