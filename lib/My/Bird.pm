use strict;
use warnings;

use My::Bird::Server;
use My::Bird::OnMemoryDatabase;
use My::Bird::Client;

package My::Bird;

sub create_server {
    my $class = shift;
    My::Bird::Server->new( My::Bird::OnMemoryDatabase->new() );
}

sub create_client {
    my $class = shift;
    my $server = shift;
    my $user_name = shift;
    My::Bird::Client->new( $server, $user_name );
}

1;

