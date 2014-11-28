package QBit::HTTPAPI;

use qbit;

use QBit::WebInterface::Response;

use QBit::HTTPAPI::XML;
use YAML::XS;

eval {require Exception::Request::UnknownMethod};

sub request {
    my ($self, $request) = @_;
    return defined($request) ? $self->{'__REQUEST__'} = $request : $self->{'__REQUEST__'};
}

sub response {
    my ($self, $response) = @_;
    return defined($response) ? $self->{'__RESPONSE__'} = $response : $self->{'__RESPONSE__'};
}

our %SERIALIZERS = (
    xml => {
        content_type => 'application/xml; charset=UTF-8',
        sub          => \&QBit::HTTPAPI::XML::pl2xml,
    },
    json => {
        content_type => 'application/json; charset=UTF-8',
        sub          => sub {
            return \to_json($_[0], pretty => $_[1]);
        },
    },
    yaml => {
        content_type => 'application/yaml; charset=UTF-8',
        sub          => sub {
            return \Dump($_[0]);
        },
    },
);

our %ACCEPT2TYPE = (
    'application/xml'  => 'xml',
    'text/xml'         => 'xml',
    'application/json' => 'json',
    'text/json'        => 'json',
    'application/yaml' => 'yaml',
    'text/yaml'        => 'yaml',
);

sub get_methods {
    my ($self) = @_;

    my $methods = {};

    package_merge_isa_data(
        ref($self) || $self,
        $methods,
        sub {
            my ($package, $res) = @_;

            my $pkg_methods = package_stash($package)->{'__API_METHODS__'} || {};
            foreach my $path (keys(%$pkg_methods)) {
                foreach my $method (keys(%{$pkg_methods->{$path}})) {
                    $methods->{$path}{$method} = $pkg_methods->{$path}{$method};
                }
            }
        },
        __PACKAGE__
    );

    return $methods;
}

sub build_response {
    my ($self) = @_;

    $self->pre_run();

    throw gettext('No request object') unless $self->request;
    $self->response(QBit::WebInterface::Response->new());

    my $methods = $self->get_methods();
    my ($path, $method, $format) = $self->get_method();

    unless (defined($format)) {
        ($format) = map {s/;.+$//; $ACCEPT2TYPE{$_} || ()} split(',', $self->request->http_header('Accept') || '');
    }
    $format = 'xml' unless defined($format);

    if (exists($methods->{$path}{$method}) && exists($SERIALIZERS{$format})) {
        my $api = $methods->{$path}{$method}->{'package'}->new(
            app   => $self,
            path  => $path,
            attrs => $methods->{$path}{$method}->{'attrs'}
        );

        try {
            my %params;
            foreach my $param (keys %{$methods->{$path}{$method}{'attrs'}{'params'} || {}}) {
                my $properties = $methods->{$path}{$method}{'attrs'}{'params'}{$param};

                my $value =
                    $properties->{'is_array'}
                  ? $self->request->param_array($param)
                  : $self->request->param($param);

                throw Exception::BadArguments gettext('Missed required parameter "%s"', $param)
                  if $properties->{'is_required'} && (!defined($value) || ($properties->{'is_array'} && !@$value));

                $params{$param} = $value if defined($value);
            }
            $api->pre_run($method, \%params);
            my $ref = $methods->{$path}{$method}{'sub'}($api, %params);
            $self->response->content_type($SERIALIZERS{$format}->{'content_type'});
            $self->response->data($SERIALIZERS{$format}->{'sub'}({result => 'ok', data => $ref}, $self->request->param('pretty')));
            $api->post_run($method, \%params, $self->response->data());
        }
        catch {
            my ($e) = @_;
            $api->on_error($method, $e);
            $self->response->content_type($SERIALIZERS{$format}->{'content_type'});
            $self->response->data(
                $SERIALIZERS{$format}->{'sub'}({result => 'error', message => $e->message(), error_type => ref($e)}, $self->request->param('pretty')));
        };
    } else {
        $self->response->status(404);
    }

    $self->post_run();

    $self->response->timelog($self->timelog);

    return TRUE;
}

sub get_method {
    my ($self) = @_;

    my $location = $self->get_option('api_location', '/');
    $location = "/$location" unless $location =~ /^\//;
    $location .= '/' unless $location =~ /\/$/;

    return $self->request->uri =~ /^\Q$location\E([^?\/#]+)\/([^?\/#\.]+)(?:\.([a-z]+))?/ ? ($1, $2, $3) : ('', '');
}

TRUE;
