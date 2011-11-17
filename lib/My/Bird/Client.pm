use strict;
use warnings;

package My::Bird::Client;

=head1 NAME

My::Bird::Client -- Bird システムにおける各ユーザーの代理人となるオブジェクトのクラス

=head1 SYNOPSIS

  use My::Bird;
  my $server = My::Bird->create_server();
  $server->signup( "alice" );
  $server->signup( "bob" );
  
  my $b1 = My::Bird->create_client( $server, "alice" );
  my $b2 = My::Bird->create_client( $server, "bob" );
  $b1->tweet( "今日はいい天気ですね" );
  $b1->follow( "bob" );
  $b2->tweet( "快晴です" );
  
  $b1->friends_timeline #=> []

=head1 DESCRIPTION

Bird システムにおいて, 各ユーザーの代理人として動くオブジェクトのクラスです. 
インスタンス生成時に, Bird システムのサーバーオブジェクトを指定します. 
サーバーオブジェクトとは密に結合していないため, My::Bird::Server 
と同じインターフェイスを持つ別のオブジェクトをサーバーオブジェクトとして使用することも可能です.

=head2 How to instantiate

インスタンス化には, クラスメソッド new を使用できます. 
また, My::Bird->create_client メソッドを使用することもできます. 

=cut

=head2 Public class methods

=over

=item My::Bird::Client->new( $server, $user_name )

My::Bird::Client オブジェクトを生成して返します. 
引数 $server でサーバーオブジェクトを指定します. 
引数 $user_name はユーザー名を指定します. このメソッド内では, 
ユーザー名が不正でないかどうか (そのユーザーが存在するかどうか) はチェックしません. 

=back

=cut

sub new {
    my $class = shift;
    my $server = shift;
    my $user_name = shift;
    my $self = bless { "server" => $server, "user_name" => $user_name }, $class;
    return $self;
}

=head2 Public instance methods

=over

=item $client->tweet( $text )

引数 $text で指定された内容を, 自身の発言としてサーバーオブジェクトに送信します. 

=item $client->follow( $user_name )

引数 $user_name で指定されたユーザーをフォローするよう, サーバーオブジェクトにリクエストを送ります. 

=item $client->my_timeline( [ $num, [ $page ] ] )

自分自身の発言一覧をサーバーオブジェクトから取得します. 
$num は取得する発言の 1 ページあたりの発言数で, $page は何ページ目の発言を取得するか 
(最新ページが 1) を指定します. 
$num のデフォルト値は 20 で, $page のデフォルト値は 1 です. 

返り値は以下の構造を持つ配列へのリファレンスです. 

  [
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    ...,
  ]

=item $client->friends_timeline( [ $num, [ $page ] ] )

自分自身と自分がフォローしているユーザーの発言一覧をサーバーオブジェクトから取得します. 
$num は取得する発言の 1 ページあたりの発言数で, $page は何ページ目の発言を取得するか 
(最新ページが 1) を指定します. 
$num のデフォルト値は 20 で, $page のデフォルト値は 1 です. 

返り値は以下の構造を持つ配列へのリファレンスです. 

  [
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    ...,
  ]

=item $client->followings

自分自身がフォローしているユーザー一覧を取得します. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=item $client->followers

自分をフォローしているユーザー一覧を取得します. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=back

=cut

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

1;
