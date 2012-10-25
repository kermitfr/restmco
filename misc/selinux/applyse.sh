cp /usr/local/bin/kermit/restmco/misc/kermitrest.te /tmp

cd /tmp
make -f /usr/share/selinux/devel/Makefile
semodule -i kermitrest.pp
rm -f /tmp/kermitrest.*

/usr/sbin/semanage port -a -t http_port_t -p tcp 6163
/usr/sbin/semanage fcontext -a -t httpd_sys_content_t "/var/www/restmco(/.*)?"

/sbin/restorecon -R /var/www/
/sbin/restorecon -R /etc/kermit

#ls -ldZ /var/www/restmco/*
cd -
