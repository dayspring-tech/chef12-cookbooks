include_recipe 'apache2'
include_recipe 'apache2::mod_php'

if node['apache']['mod_php']['module_name'] == 'php7'
    link "#{node['apache']['dir']}/mods-enabled/php.conf" do
        to "#{node['apache']['dir']}/mods-available/php.conf"
    end
end
