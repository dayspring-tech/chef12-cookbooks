# once only, replace chef's CA certs with the system ones

script "store original chef certs" do
    interpreter "bash"
    user "root"
    code <<-EOH
        mv /opt/chef/embedded/ssl/certs/cacert.pem /opt/chef/embedded/ssl/certs/original.pem
    EOH
    not_if { ::File.exist?('/opt/chef/embedded/ssl/certs/original.pem') }
end

link "/opt/chef/embedded/ssl/certs/cacert.pem" do
    to "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
    not_if { ::File.exist?('/opt/chef/embedded/ssl/certs/cacert.pem') }
end
