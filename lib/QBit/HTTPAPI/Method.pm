package QBit::HTTPAPI::Method;

use qbit;

use base qw(QBit::Application::Part);

sub _register_method {
    my ($package, $sub) = @_;

    my $pkg_stash = package_stash($package);
    $pkg_stash->{'__API_METHODS__'} = [] unless exists($pkg_stash->{'__API_METHODS__'});

    push(
        @{$pkg_stash->{'__API_METHODS__'}},
        {
            sub     => $sub,
            package => $package,
        }
    );
}

sub _set_method_attr {
    my ($package, $sub, $name, $value) = @_;

    my $pkg_stash = package_stash($package);
    $pkg_stash->{'__API_METHODS_ATTRS__'} = {} unless exists($pkg_stash->{'__API_METHODS_ATTRS__'});

    $pkg_stash->{'__API_METHODS_ATTRS__'}{$package, $sub}{$name} = $value;
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $sub, @attrs) = @_;

    my @unknown_attrs = ();

    foreach my $attr (@attrs) {
        if ($attr =~ /^METHOD$/) {
            $package->_register_method($sub);
        } elsif ($attr =~ /^TITLE(?:\s*\(\s*'\s*([\w\d\s-]+)\s*'\s*\))?$/) {
            $package->_set_method_attr($sub, title => $1);
        } elsif ($attr =~ /^PARAMS\s*\((.+)\)\s*$/) {
            my @vars = split(/\s*,\s*/, $1);
            my %vars;
            foreach (@vars) {
                die "Invalid mehtod param '$_'" unless /^(\!)?([_\w\d]+)(\[\])?/;
                $vars{$2} = {
                    is_required => !!$1,
                    is_array    => !!$3,
                };
            }
            $package->_set_method_attr($sub, params => \%vars);
        } else {
            push(@unknown_attrs, $attr);
        }
    }

    return @unknown_attrs;
}

sub import {
    my ($package, %opts) = @_;

    $package->SUPER::import(%opts);

    $opts{'path'} ||= '';

    my $app_pkg = caller();
    throw gettext('Use only in QBit::HTTPAPI and QBit::Application descendant')
      unless $app_pkg->isa('QBit::HTTPAPI')
          && $app_pkg->isa('QBit::Application');

    my $pkg_stash = package_stash($package);

    my $app_pkg_stash = package_stash($app_pkg);
    $app_pkg_stash->{'__API_METHODS__'} = {}
      unless exists($app_pkg_stash->{'__API_METHODS__'});

    my $pkg_sym_table = package_sym_table($package);

    foreach my $method (@{$pkg_stash->{'__API_METHODS__'} || []}) {
        my ($name) =
          grep {!ref($pkg_sym_table->{$_}) && $method->{'sub'} == \&{$pkg_sym_table->{$_}}} keys %$pkg_sym_table;

        $method->{'attrs'} = $pkg_stash->{'__API_METHODS_ATTRS__'}{$method->{'package'}, $method->{'sub'}} || {};

        throw gettext("HTTPAPI method \"%s\" is exists in package \"%s\"",
            $name, $app_pkg_stash->{'__API_METHODS__'}{$opts{'path'}}{$name}{'package'})
          if exists($app_pkg_stash->{'__API_METHODS__'}{$opts{'path'}}{$name});
        $app_pkg_stash->{'__API_METHODS__'}{$opts{'path'}}{$name} = $method;
    }

    {
        no strict 'refs';
        foreach my $method (qw(get_option)) {
            *{"${package}::${method}"} = sub {shift->app->$method(@_)};
        }
    }
}

sub pre_run  { }
sub post_run { }
sub on_error { }

TRUE;
