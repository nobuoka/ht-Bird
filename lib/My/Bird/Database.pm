use strict;
use warnings;
use Carp;

package My::Bird::Database;

sub add_user {
    my $self = shift;
    my $user_name = shift;
    die "user $user_name already exists" if defined $self->{"users"}{$user_name};
    $self->{"users"}{$user_name} = {
         "followings" => {},
         "followers"  => {},
    }
}

sub add_tweet {
    my $self = shift;
    my $user_name = shift;
    my $text = shift;
    unshift( @{$self->{"tweets"}}, { "user_name" => $user_name, "text" => $text } );
}

sub create_following_relationship {
    my $self = shift;
    my ( $sun, $tun ) = @_;
    my $un = $self->{"users"};
    ( $un->{$sun} and $un->{$tun} ) or die "user not exists";
    if( defined $un->{$sun}{"followings"}{$tun} ) {
        # already follow
        return 0;
    }
    $un->{$sun}{"followings"}{$tun} = 1;
    $un->{$tun}{"followers"}{$sun}  = 1;
    return 1;
}

sub select_tweets {
    my $self = shift;
    my %cond = @_; # $cond{"user_names"}, $cond{"limit"}
    # 
    my @tweets = @{$self->{"tweets"}};
    # 発言者による絞込み
    if( defined $cond{"tweet_users"} ) {
        my %unaa = map { ( $_, 1  ) } @{$cond{"tweet_users"}};
        @tweets = grep { defined $unaa{$_->{"user_name"}} } @tweets;
    }
    # limit による絞込み
    if( defined $cond{"limit"} ) {
        $self->__limit( \@tweets, $cond{"limit"} );
        #unshift( @{$cond{"limit"}}, 0 ) if @{$cond{"limit"}} == 1;
        #my ( $b, $e ) = @{$cond{"limit"}};
        #$e += $b - 1;
        #if( $#tweets < $b ) {
        #    @tweets = ();
        #} else {
        #    $e = ( $#tweets < $e ? $#tweets : $e );
        #    @tweets = @tweets[$b..$e];
        #}
    }
    return \@tweets;
}

sub select_followers {
    my $self = shift;
    my %cond = @_; # $cond{"user_name"}, $cond{"limit"}
    # 誰のフォロワー？
    if( ! defined $cond{"user_name"} ) {
        # 必須の条件
        Carp::croak "必須の条件が指定されていない";
    }
    my $u = $self->{"users"}{$cond{"user_name"}};
    if( ! defined $u ) {
        Carp::croak "指定されたユーザー (" . $cond{"user_name"} . ") は存在しません";
    }
    my @followers = sort keys %{$u->{"followers"}};
    # limit による絞込み
    if( defined $cond{"limit"} ) {
        $self->__limit( \@followers, $cond{"limit"} );
    }
    return \@followers;
}

sub select_followings {
    my $self = shift;
    my %cond = @_; # $cond{"user_name"}, $cond{"limit"}
    # 誰のフォロワー？
    if( ! defined $cond{"user_name"} ) {
        # 必須の条件
        Carp::croak "必須の条件が指定されていない";
    }
    my $u = $self->{"users"}{$cond{"user_name"}};
    if( ! defined $u ) {
        Carp::croak "指定されたユーザー (" . $cond{"user_name"} . ") は存在しません";
    }
    my @followings = sort keys %{$u->{"followings"}};
    # limit による絞込み
    if( defined $cond{"limit"} ) {
        $self->__limit( \@followings, $cond{"limit"} );
    }
    return \@followings;
}

sub _new {
    my $class = shift;
    my $self  = bless {
        "users"  => {},
        "tweets" => [],
    }, $class;
    return $self;
}

sub __limit {
    my $self = shift;
    my ( $aref, $lcond ) = @_;
    unshift( @{$lcond}, 0 ) if @{$lcond} == 1;
    my ( $b, $e ) = @{$lcond};
    $e += $b - 1;
    if( $#$aref < $b ) {
        @{$aref} = ();
    } else {
        $e = ( $#$aref < $e ? $#$aref : $e );
        @{$aref} = @{$aref}[$b..$e];
    }
}

1;

