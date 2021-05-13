node[:deploy].each do |application, deploy|

	if node['vagrant']
    before_symlinkfile = "#{deploy[:deploy_to]}/deploy/before_symlink.rb"
    if File.exist?(before_symlinkfile)
        require 'ostruct'
        new_resource = OpenStruct.new
        new_resource.params = {
            :deploy_data => deploy,
            :app => application
        }
        release_path = "#{deploy[:deploy_to]}"
        external = File.read before_symlinkfile
        eval external
    end
  end
end
