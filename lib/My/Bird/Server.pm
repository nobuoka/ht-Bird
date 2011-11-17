use strict;
use warnings;
use Carp;

package My::Bird::Server;

sub new {
    my $class = shift;
    my $db = shift;
    my $self  = bless {}, $class;
    $self->{"db"} = $db;
    return $self;
}

sub signup {
    my $self = shift;
    my $user_name = shift;
    my $db = $self->{"db"};
    eval{ $db->add_user( $user_name ) };
    Carp::croak if $@;
}

sub post_tweet {
    my $self = shift;
    my ( $user_name, $text ) = @_;
    ( $user_name and $text ) or Carp::croak "invalid arguments";
    $self->{"db"}->add_tweet( $user_name, $text );
}

sub request_following {
    my $self = shift;
    my $source_user_name = shift;
    my $target_user_name = shift;
    $self->{"db"}->create_following_relationship( $source_user_name, $target_user_name );
}

sub get_user_timeline {
    my $self = shift;
    my ( $user_name, $bidx, $num ) = @_;
    ( $user_name and ( defined $bidx ) and ( defined $num ) ) or Carp::croak "invalid arguments";
    $self->{"db"}->select_tweets( 
            "tweet_users" => [ $user_name ], "limit" => [ $bidx, $num ] );
}

sub get_friends_timeline {
    my $self = shift;
    my ( $user_name, $bidx, $num ) = @_;
    ( $user_name and ( defined $bidx ) and ( defined $num ) ) or Carp::croak "invalid arguments";
    my $db = $self->{"db"};
    my $users = $db->select_followings( "user_name" => $user_name );
    push @{$users}, $user_name;
    $db->select_tweets( "tweet_users" => $users, "limit" => [ $bidx, $num ] );
}

sub get_followings {
    my $self = shift;
    my $user_name = shift;
    $self->{"db"}->select_followings( "user_name" => $user_name );
}

sub get_followers {
    my $self = shift;
    my $user_name = shift;
    $self->{"db"}->select_followers( "user_name" => $user_name );
}


1;

