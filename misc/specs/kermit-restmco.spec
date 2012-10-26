%define gitrev b9d4a55

Name:      kermit-restmco 
Summary:   A simple REST server used to communicate with Mcollective 
Version:   2.0 
Release:   5%{?dist}
License:   GPLv3
Group:     System Tools 
#Source0:   %{name}-%{version}.tar.gz 
Source0:   thinkfr-restmco-%{gitrev}.tar.gz 
Requires:  rubygem-daemons, rubygem-sinatra, mcollective-common, rubygem-inifile
%if "%dist" == ".el5"
Requires: selinux-policy-devel
%else 
Requires: selinux-policy
%endif
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch

%description
A simple REST server in ruby and sinatra, used to communicate with Mcollective 

%prep
%setup -n thinkfr-restmco-%{gitrev}

%build

%install
rm -rf %{buildroot}
install -d -m 755 %{buildroot}/usr/local/bin/kermit/restmco
install -d -m 755 %{buildroot}/usr/local/bin/kermit/restmco/misc
install -d -m 755 %{buildroot}/etc/init.d
install -d -m 755 %{buildroot}/etc/kermit
install -d -m 755 %{buildroot}/var/log
install -d -m 755 %{buildroot}/var/www/restmco
install -d -m 755 %{buildroot}/var/www/restmco/public
install -d -m 755 %{buildroot}/var/www/restmco/tmp
install mc-rpc-restserver.rb %{buildroot}/usr/local/bin/kermit/restmco
install mc-rpc-restserver-control.rb %{buildroot}/usr/local/bin/kermit/restmco
install misc/service/kermit-restmco %{buildroot}/etc/init.d 
install misc/sysconfig/kermit-restmco.cfg %{buildroot}/etc/kermit
install misc/httpd/restmco.conf %{buildroot}/usr/local/bin/kermit/restmco/misc
install misc/selinux/kermitrest.te %{buildroot}/usr/local/bin/kermit/restmco/misc
install misc/selinux/applyse.sh %{buildroot}/usr/local/bin/kermit/restmco/misc
install misc/log/kermit-restmco.log %{buildroot}/var/log 
install mc-rpc-restserver.rb %{buildroot}/var/www/restmco
install passenger/config.ru %{buildroot}/var/www/restmco
install passenger/tmp/restart.txt %{buildroot}/var/www/restmco/tmp


%clean
rm -rf %{buildroot}

%pre
mkdir -p /usr/local/bin/kermit/restmco

%files
%defattr(0644,root,root,-)
%attr(0755, root, root) /usr/local/bin/kermit/restmco/mc-rpc-restserver-control.rb
/usr/local/bin/kermit/restmco/mc-rpc-restserver.rb
/usr/local/bin/kermit/restmco/misc/restmco.conf
/usr/local/bin/kermit/restmco/misc/kermitrest.te
%attr(0755,root,root) /usr/local/bin/kermit/restmco/misc/applyse.sh
%attr(0755,root,root) /etc/init.d/kermit-restmco
%config(noreplace) %attr(0755,root,root) /etc/kermit/kermit-restmco.cfg
%attr(0644,nobody,nobody) /var/log/kermit-restmco.log
%attr(0755,root,root) /var/www/restmco
/var/www/restmco/mc-rpc-restserver.rb
/var/www/restmco/config.ru
%attr(0755,root,root) /var/www/restmco/public
%attr(0755,root,root) /var/www/restmco/tmp
/var/www/restmco/tmp/restart.txt

%changelog
* Fri Oct 26 2012 Marco Mornati
- Requires for selinux
* Fri Oct 26 2012 Louis Coilliot
- patch for JSON.dump compat with rb 1.8.7
* Fri Oct 26 2012 Louis Coilliot
- mco agent filter
* Thu Oct 25 2012 Louis Coilliot
- provide script for applying selinux conf
- proper display of filter arrays in the logs
* Wed Oct 24 2012 Louis Coilliot
- provide selinux module 
* Wed Oct 24 2012 Louis Coilliot
- simplified installation for passenger
* Mon Oct 22 2012 Marco Mornati
- Changed request type from GET to POST with a JSON Body Object for all
  parameters
- Created log file configurable with /etc/kermit/kermit-restmco
* Fri Nov 11 2011 Louis Coilliot
- identity_filter=host01_OR_host02 
* Mon Oct 24 2011 Louis Coilliot
- fixed problem with multiple options
* Wed Aug 24 2011 Louis Coilliot 
- fixed problem with limit filter
* Sat Aug 20 2011 Louis Coilliot
- credits and improved comments
* Thu Aug 18 2011 Louis Coilliot
- enable multiple filters in one request
* Thu Aug 18 2011 Louis Coilliot
- Initial build

