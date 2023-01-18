script "compile and enable imagick extension" do
	interpreter "bash"
	user "root"
	code <<-EOH
	yum install -y gcc make wget tar ImageMagick ImageMagick-devel
	echo | pecl install imagick
	echo "extension=imagick.so" | tee /etc/php.d/imagick.ini
	EOH
end
