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

%files
%defattr(0755,root,root)
/var/chef/cookbooks/postgresql
%defattr(0644,root,root)
/var/chef/cookbooks/postgresql/README.md


%doc

%changelog
* Wed Jan 31 2018 Juan J. Prieto <jjprieto@redborder.com> - 0.0.1-1
- first spec version
