use strict;
use warnings;

use My::Bird;

package test::Test01;
use base qw( Test::Class );
use Test::More;

# インスタンス化できることの確認
sub test_of_instantiation : Tests {
    my $self = shift;
    my $bird_server = My::Bird->create_server();
    ok( $bird_server->isa( "My::Bird::Server" ) );
    $bird_server->signup( "username" );
    my $bird1 = My::Bird->create_client( $bird_server, "username" );
    ok( $bird1->isa( "My::Bird::Client" ) );
}

# つぶやきをして, 自分の Timeline で表示できることを確認
sub test_of_tweeting : Tests {
    my $self = shift;
    my $bird_server = My::Bird->create_server();
    my $user_name = "Alice";
    $bird_server->signup( $user_name );
    my $bird1 = My::Bird->create_client( $bird_server, $user_name );
    $bird1->tweet( "今日は暑いですね" );
    $bird1->tweet( "こんな日はアイスを食べるに限る" );
    is_deeply( $bird1->my_timeline, [ 
        { "user_name" => $user_name, "text" => "こんな日はアイスを食べるに限る" }, 
        { "user_name" => $user_name, "text" => "今日は暑いですね" },
     ] );
}

# フォローして, フォロー/フォロワー関係を取得できることを確認
sub test_of_following : Tests {
    my $self = shift;
    my $bird_server = My::Bird->create_server();
    $bird_server->signup( "Alice" );
    $bird_server->signup( "Bob" );
    $bird_server->signup( "Charlie" );
    $bird_server->signup( "Dave" );
    my $b1 = My::Bird->create_client( $bird_server, "Alice" );
    my $b2 = My::Bird->create_client( $bird_server, "Bob" );
    my $b3 = My::Bird->create_client( $bird_server, "Charlie" );
    my $b4 = My::Bird->create_client( $bird_server, "Dave" );
    ok( $b1->follow( "Bob" ) );
    ok( $b1->follow( "Dave" ) );
    ok( $b2->follow( "Alice" ) );
    # Alice と Bob は相互フォロー, Alice は Dave を one-way フォロー
    is_deeply( [ sort @{$b1->followers} ], [ "Bob" ] );
    is_deeply( [ sort @{$b2->followers} ], [ "Alice" ] );
    is_deeply( [ sort @{$b3->followers} ], [ ] );
    is_deeply( [ sort @{$b4->followers} ], [ "Alice" ] );
    is_deeply( [ sort @{$b1->followings} ], [ "Bob", "Dave" ] );
    is_deeply( [ sort @{$b2->followings} ], [ "Alice" ] );
    is_deeply( [ sort @{$b3->followings} ], [ ] );
    is_deeply( [ sort @{$b4->followings} ], [ ] );
}

# フォローしてる人の発言一覧を取得できることを確認
sub test_of_friends_timeline : Tests {
    my $self = shift;
    my $bird_server = My::Bird->create_server();
    $bird_server->signup( "Alice" );
    $bird_server->signup( "Bob" );
    $bird_server->signup( "Charlie" );
    $bird_server->signup( "Dave" );
    my $b1 = My::Bird->create_client( $bird_server, "Alice" );
    my $b2 = My::Bird->create_client( $bird_server, "Bob" );
    my $b3 = My::Bird->create_client( $bird_server, "Charlie" );
    my $b4 = My::Bird->create_client( $bird_server, "Dave" );
    ok( $b1->follow( "Bob" ) );
    ok( $b1->follow( "Dave" ) );
    ok( $b2->follow( "Alice" ) );
    # Alice と Bob は相互フォロー, Alice は Dave を one-way フォロー
    $b1->tweet( "Alice です。" );
    $b2->tweet( "あか" );
    $b3->tweet( "なま" );
    $b4->tweet( "てつ" );
    $b1->tweet( "こな" );
    $b2->tweet( "へん" );
    $b3->tweet( "みな" );
    $b4->tweet( "ええ" );
    is_deeply( $b1->friends_timeline, [
        { "user_name" => "Dave", "text" => "ええ" },
        { "user_name" => "Bob", "text" => "へん" },
        { "user_name" => "Alice", "text" => "こな" },
        { "user_name" => "Dave", "text" => "てつ" },
        { "user_name" => "Bob", "text" => "あか" },
        { "user_name" => "Alice", "text" => "Alice です。" },
    ] );
}

__PACKAGE__->runtests();

1;
