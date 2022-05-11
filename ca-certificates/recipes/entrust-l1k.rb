# this recipe adds the Entrust L1K intermediate CA to the system's trust bundle

script "install entrust-l1k intermediate CA (amazon)" do
    interpreter "bash"
    user "root"
    code <<-EOH
    curl -L -o /usr/share/pki/ca-trust-source/anchors/entrust_l1k.crt https://entrust.com/root-certificates/entrust_l1k.cer
    update-ca-trust 
    EOH
    only_if { platform_family?('rhel', 'amazon', 'fedora', 'suse') }
end

script "install entrust-l1k intermediate CA (ubuntu)" do
    interpreter "bash"
    user "root"
    code <<-EOH
    sudo curl -L -o /usr/local/share/ca-certificates/entrust_l1k.crt https://entrust.com/root-certificates/entrust_l1k.cer
    sudo update-ca-certificates
    EOH
    only_if { platform_family?('debian') }
end
