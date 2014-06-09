use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";

use Test::More;
use Test::Deep;

use qbit;

use TestHTTPAPI;
use TestRequest;

my $api = new_ok('TestHTTPAPI');

cmp_deeply(
    $api->get_methods,
    {
        test1 => {
            method1 => {
                attrs => {
                    title  => 'Test method 1',
                    params => {
                        prm => {
                            is_required => FALSE,
                            is_array    => FALSE,
                        },
                        rprm => {
                            is_required => TRUE,
                            is_array    => FALSE,
                        },
                        aprm => {
                            is_required => FALSE,
                            is_array    => TRUE,
                        },
                        raprm => {
                            is_required => TRUE,
                            is_array    => TRUE,
                        },
                    },
                },
                package => 'TestHTTPAPI::Method::Test1',
                sub     => ignore,
            },
            method2 => {
                attrs   => {title => 'Test method - 2'},
                package => 'TestHTTPAPI::Method::Test1',
                sub     => ignore,
            }
        },
        test2 => {
            method1 => {
                attrs   => {title => 'Test method 1'},
                package => 'TestHTTPAPI::Method::Test2',
                sub     => ignore,
            },
        }
    },
    'Checking methods'
);

$api->request(TestRequest->new(uri => '/test1/method1'));
cmp_deeply([$api->get_method()], ['test1', 'method1', undef], 'Checking get_method, uri: /test1/method1');

$api->request(TestRequest->new(uri => '/test1/method1/'));
cmp_deeply([$api->get_method()], ['test1', 'method1', undef], 'Checking get_method, uri: /test1/method1/');

$api->request(TestRequest->new(uri => '/test1/method1?p=1'));
cmp_deeply([$api->get_method()], ['test1', 'method1', undef], 'Checking get_method, uri: /test1/method1?p=1');

$api->request(TestRequest->new(uri => '/test1/method1#p=1'));
cmp_deeply([$api->get_method()], ['test1', 'method1', undef], 'Checking get_method, uri: /test1/method1#p=1');

$api->request(TestRequest->new(uri => '/test1/method1.json'));
cmp_deeply([$api->get_method()], ['test1', 'method1', 'json'], 'Checking get_method, uri: /test1/method1.json');

$api->request(TestRequest->new(uri => '/test1/method1.json/'));
cmp_deeply([$api->get_method()], ['test1', 'method1', 'json'], 'Checking get_method, uri: /test1/method1/.json');

$api->request(TestRequest->new(uri => '/test1/method1.json?p=1'));
cmp_deeply([$api->get_method()], ['test1', 'method1', 'json'], 'Checking get_method, uri: /test1/method1.json?p=1');

$api->request(TestRequest->new(uri => '/test1/method1.json#p=1'));
cmp_deeply([$api->get_method()], ['test1', 'method1', 'json'], 'Checking get_method, uri: /test1/method1.json#p=1');

foreach my $location ('api', '/api', '/api/') {
    $api->set_option(api_location => $location);
    $api->request(TestRequest->new(uri => '/api/test1/method1'));
    cmp_deeply([$api->get_method()], ['test1', 'method1', undef], "Checking get_method with location '$location'");
}

done_testing();
