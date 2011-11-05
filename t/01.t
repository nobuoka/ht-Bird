use strict;
use warnings;

use My::Bird;

package test::Test01;
use base qw( Test::Class );
use Test::More;

__PACKAGE__->runtests();

1;

