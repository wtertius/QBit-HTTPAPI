package TestHTTPAPI;

use qbit;

use base qw(QBit::HTTPAPI QBit::Application);

use TestHTTPAPI::Method::Test1 path => 'test1';
use TestHTTPAPI::Method::Test2 path => 'test2';

TRUE;
