use strict;
use warnings;

use My::Bird::Server;

package My::Bird;

sub create_server {
    my $class = shift;
    My::Bird::Server->_new();
}

1;

