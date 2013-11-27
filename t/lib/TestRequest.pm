package TestRequest;

use qbit;

use base qw(QBit::WebInterface::Request);

sub uri {$_[0]->{'uri'}}

TRUE;
