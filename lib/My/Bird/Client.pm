use strict;
use warnings;

package My::Bird::Client;

sub tweet {
    my $self = shift;
    my $text = shift;
    $self->{"server"}->post_tweet( $self->{"user_name"}, $text );
}

sub follow {
    my $self = shift;
    my $target_user_name = shift;
    $self->{"server"}->request_following( $self->{"user_name"}, $target_user_name );
}

sub my_timeline {
    my $self = shift;
    my ( $num, $page ) = @_;
    $num = 20 unless defined $num;
    $page ? ( -- $page ) : ( $page = 0 );
    my $bidx = $page * $num;
    $self->{"server"}->get_user_timeline( $self->{"user_name"}, $bidx, $num );
}

sub friends_timeline {
    my $self = shift;
    my ( $num, $page ) = @_;
    $num = 20 unless defined $num;
    $page ? ( -- $page ) : ( $page = 0 );
    my $bidx = $page * $num;
    $self->{"server"}->get_friends_timeline( $self->{"user_name"}, $bidx, $num );
}

sub followings {
    my $self = shift;
    $self->{"server"}->get_followings( $self->{"user_name"} );
}

sub followers {
    my $self = shift;
    $self->{"server"}->get_followers( $self->{"user_name"} );
}

sub _new {
    my $class = shift;
    my $server = shift;
    my $user_name = shift;
    my $self = bless { "server" => $server, "user_name" => $user_name }, $class;
    return $self;
}

1;

