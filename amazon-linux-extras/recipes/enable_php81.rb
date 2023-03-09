execute "enable php8.1" do
    command "amazon-linux-extras enable php8.1"
    user "root"
    action :run
end
