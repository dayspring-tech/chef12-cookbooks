script "compile and enable redis extension" do
	interpreter "bash"
	user "root"
	code <<-EOH
	yum install -y gcc make
	echo | pecl install redis
	echo "extension=redis.so" | tee /etc/php.d/redis.ini
	EOH
end
