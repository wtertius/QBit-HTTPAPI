package TestHTTPAPI::Method::Test2;

use qbit;

use base qw(QBit::HTTPAPI::Method);

sub method1 : METHOD : TITLE('Test method 1') {
    my ($self, %opts) = @_;
}

TRUE;
