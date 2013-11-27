package TestHTTPAPI::Method::Test1;

use qbit;

use base qw(QBit::HTTPAPI::Method);

sub method1 : METHOD : PARAMS(prm, !rprm, aprm[], !raprm[]) : TITLE('Test method 1') {
    my ($self, %opts) = @_;
}

sub method2 : METHOD : TITLE('Test method 2') {
    my ($self, %opts) = @_;
}

TRUE;