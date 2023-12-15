Name: cookbook-postgresql
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: PostgreSQL cookbook to install and configure it in redborder platform.

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-example
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/postgresql
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/postgresql
chmod -R 0755 %{buildroot}/var/chef/cookbooks/postgresql
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/postgresql/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload postgresql'
  ;;
esac


%files
%defattr(0755,root,root)
/var/chef/cookbooks/postgresql
%defattr(0644,root,root)
/var/chef/cookbooks/postgresql/README.md


%doc

%changelog
* Fri Dec 15 2023 David Vanhoucke <dvanhoucke@redborder.com> - 0.1.7-1
- Add support for sync ip
* Fri Dec 15 2023 David Vanhoucke <dvanhoucke@redborder.com> - 0.1.6-1
- Add support for grand access cript
* Fri Dec 15 2023 David Vanhoucke <dvanhoucke@redborder.com> - 0.1.5-1
- Fix service HA
* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com> - 0.1.2-1
- change register to consul
* Thu Feb 1 2018 Juan J. Prieto <jjprieto@redborder.com> - 0.0.2-1
- Add post upgrade cookbook upload
* Wed Jan 31 2018 Juan J. Prieto <jjprieto@redborder.com> - 0.0.1-1
- first spec version
