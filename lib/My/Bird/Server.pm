use strict;
use warnings;
use Carp;

package My::Bird::Server;

=head1 NAME

My::Bird::Server -- Bird システムのサーバーオブジェクト

=head1 SYNOPSIS

  use My::Bird;
  my $server = My::Bird->create_server();
  $server->signup( "alice" );
  $server->signup( "bob" );
  
=head1 DESCRIPTION

Bird システムのサーバーオブジェクトとして, ユーザーの発言やフォロー, 
フォロワー関係などの情報を保持します. 
実際にデータを保持するのはデータベースオブジェクトであり, 
使用するデータベースオブジェクトはサーバーオブジェクトの生成時に指定します. 

これは習作であるため, ユーザー認証等の機能はありません. 
あるユーザーとしてサーバーオブジェクトにリクエストを送るためには, 
そのユーザーのユーザー名を指定するだけで構いません. 

=head2 How to instantiate

インスタンス化は, クラスメソッド new を使うことで実行できます. 
また, My::Bird->create_server メソッドを使うことで, 
My::Bird::OnMemoryDatabase オブジェクトをデータベースオブジェクトとする 
My::Bird::Server オブジェクトを生成できます. 

=cut

=head2 Public class methods 

=over

=item My::Bird::Server->new( $db )

My::Bird::Server オブジェクトを生成して返します. 
使用するデータベースオブジェクトを引数 $db で指定します. 

=back

=cut

sub new {
    my $class = shift;
    my $db = shift;
    my $self  = bless {}, $class;
    $self->{"db"} = $db;
    return $self;
}

=head2 Public instance methods

=over

=item $server->signup( $user_name )

$user_name で指定されたユーザー名のユーザーを新たに作ります. 
既に存在しているユーザー名が指定された場合は, 例外を発生させます. 

=item $server->post_tweet( $user_name, $text )

$user_name で指定されたユーザー名のユーザーの発言として $text を登録します. 
存在しないユーザー名を指定すると例外が発生します. 

=item $server->request_following( $user_name, $target_user_name )

$user_name で指定されたユーザー名のユーザーが, 
$target_user_name で指定されたユーザー名のユーザーをフォローしている状態にします. 
存在しないユーザー名を指定すると例外が発生します. 

=item $server->get_user_timeline( $user_name, $bidx, $num )

$user_name で指定されたユーザー名のユーザーの発言一覧のうち, 
インデックス $bidx (最新の発言がインデックス 0) から個数 $num だけ取得します. 
存在しないユーザー名を指定すると例外が発生します. 

返り値は以下の構造を持つ配列へのリファレンスです. 

  [
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    ...,
  ]

=item $server->get_friends_timeline( $user_name, $bidx, $num )

$user_name で指定されたユーザー名のユーザーとフォローしているユーザーの発言一覧のうち, 
インデックス $bidx (最新の発言がインデックス 0) から個数 $num だけ取得します. 
存在しないユーザー名を指定すると例外が発生します. 

返り値は以下の構造を持つ配列へのリファレンスです. 

  [
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    ...,
  ]

=item $server->get_followings( $user_name )

$user_name で指定されたユーザー名のユーザーがフォローしているユーザーのユーザー名一覧を返します.  
存在しないユーザー名を指定すると例外が発生します. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=item $server->get_followers( $user_name )

$user_name で指定されたユーザー名のユーザーをフォローしているユーザーのユーザー名一覧を返します.  
存在しないユーザー名を指定すると例外が発生します. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=back

=cut

sub signup {
    my $self = shift;
    my $user_name = shift;
    Carp::croak "既に存在するユーザー名です." if $self->__check_user_existence( $user_name );
    my $db = $self->{"db"};
    eval{ $db->add_user( $user_name ) };
    Carp::croak if $@;
}

sub post_tweet {
    my $self = shift;
    my ( $user_name, $text ) = @_;
    ( $user_name and $text ) or Carp::croak "invalid arguments";
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    $self->{"db"}->add_tweet( $user_name, $text );
}

sub request_following {
    my $self = shift;
    my $user_name = shift;
    my $target_user_name = shift;
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    $self->{"db"}->create_following_relationship( $user_name, $target_user_name );
}

sub get_user_timeline {
    my $self = shift;
    my ( $user_name, $bidx, $num ) = @_;
    ( $user_name and ( defined $bidx ) and ( defined $num ) ) or Carp::croak "invalid arguments";
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    $self->{"db"}->select_tweets( 
            "tweet_users" => [ $user_name ], "limit" => [ $bidx, $num ] );
}

sub get_friends_timeline {
    my $self = shift;
    my ( $user_name, $bidx, $num ) = @_;
    ( $user_name and ( defined $bidx ) and ( defined $num ) ) or Carp::croak "invalid arguments";
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    my $db = $self->{"db"};
    my $users = $db->select_followings( "user_name" => $user_name );
    push @{$users}, $user_name;
    $db->select_tweets( "tweet_users" => $users, "limit" => [ $bidx, $num ] );
}

sub get_followings {
    my $self = shift;
    my $user_name = shift;
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    $self->{"db"}->select_followings( "user_name" => $user_name );
}

sub get_followers {
    my $self = shift;
    my $user_name = shift;
    Carp::croak "存在しないユーザー名です." if ! $self->__check_user_existence( $user_name );
    $self->{"db"}->select_followers( "user_name" => $user_name );
}

sub __check_user_existence {
    my $self = shift;
    my $user_name = shift;
    my $users = $self->{"db"}->select_users( "user_names" => [ $user_name ] );
    return ( 0 != @$users );
}

1;

