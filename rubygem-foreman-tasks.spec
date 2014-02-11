%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name foreman-tasks

%define rubyabi 1.9.1
%global foreman_bundlerd_dir /usr/share/foreman/bundler.d

Summary: Tasks support for Foreman with Dynflow integration
Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.1.4
Release: 1%{?dist}
Group: Development/Libraries
License: GPLv2
URL: http://github.com/iNecas/foreman-tasks
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem
Requires: foreman

%if 0%{?fedora} > 18
Requires:       %{?scl_prefix}ruby(release)
%else
Requires: %{?scl_prefix}ruby(abi) = 1.9.1
%endif

Requires: %{?scl_prefix}rubygem(dynflow)
Requires: %{?scl_prefix}rubygem(sequel)
Requires: %{?scl_prefix}rubygem(sinatra)
Requires: %{?scl_prefix}rubygem(daemons)
Requires: %{?scl_prefix}rubygems
BuildRequires: %{?scl_prefix}rubygems-devel

%if 0%{?fedora} > 18
BuildRequires:       %{?scl_prefix}ruby(release)
%else
BuildRequires: %{?scl_prefix}ruby(abi) = 1.9.1
%endif
BuildRequires: %{?scl_prefix}rubygems
BuildArch: noarch
Provides: %{?scl_prefix}rubygem(%{gem_name}) = %{version}

%description
The goal of this plugin is to unify the way of showing task statuses across
the Foreman instance.  It defines Task model for keeping the information
about the tasks and Lock for assigning the tasks to resources. The locking
allows dealing with preventing multiple colliding tasks to be run on the
same resource. It also optionally provides Dynflow infrastructure for using
it for managing the tasks.

%package doc
BuildArch:  noarch
Requires:   %{?scl_prefix}%{pkg_name} = %{version}-%{release}
Summary:    Documentation for rubygem-%{gem_name}

%description doc
This package contains documentation for rubygem-%{gem_name}.

%prep
%setup -n %{pkg_name}-%{version} -q -c -T
mkdir -p .%{gem_dir}
%{?scl:scl enable %{scl} "}
gem install --local --install-dir .%{gem_dir} \
            --force %{SOURCE0} --no-rdoc --no-ri
%{?scl:"}

%build

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{foreman_bundlerd_dir}
cat <<GEMFILE > %{buildroot}%{foreman_bundlerd_dir}/foreman-tasks.rb
gem 'foreman-tasks'
GEMFILE


%files
%dir %{gem_instdir}
%{gem_instdir}/app
%{gem_instdir}/bin
%{gem_instdir}/lib
%{gem_instdir}/config
%{gem_instdir}/db
%exclude %{gem_cache}
%{gem_spec}
%{foreman_bundlerd_dir}/foreman-tasks.rb
%doc %{gem_instdir}/MIT-LICENSE

%exclude %{gem_instdir}/test
%exclude %{gem_dir}/cache/%{gem_name}-%{version}.gem

%files doc
%doc %{gem_instdir}/MIT-LICENSE
%doc %{gem_instdir}/README.md

%changelog
* Tue Feb 11 2014 Ivan Nečas <inecas@redhat.com> 0.1.4-1
- Fix action triggering (inecas@redhat.com)
- Support sync actions when hooking into Foreman model with Dynflow
  (inecas@redhat.com)
- Fix eager loading with lazy world initialization (inecas@redhat.com)
- Add ForemanTasks::Triggers module to include trigger methods where needed
  (git@pitr.ch)

* Wed Jan 29 2014 Ivan Nečas <inecas@redhat.com> 0.1.3-1
- enforce local executor in rake tasks (inecas@redhat.com)

* Wed Jan 29 2014 Ivan Nečas <inecas@redhat.com> 0.1.2-1
- Delay world initialization when using PhusionPassenger (inecas@redhat.com)
* Mon Jan 27 2014 Ivan Nečas <inecas@redhat.com> 0.1.1-1
- Use separate database when running on sqlite3 (inecas@redhat.com)

* Thu Jan 23 2014 Ivan Nečas <inecas@redhat.com> 0.1.0-1
- new package built with tito

