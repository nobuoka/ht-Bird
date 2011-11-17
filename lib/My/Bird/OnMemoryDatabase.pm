use strict;
use warnings;
use Carp;

package My::Bird::OnMemoryDatabase;

=head1 NAME

My::Bird::OnMemoryDatabase -- Bird システムのデフォルトデータベースオブジェクト

=head1 DESCRIPTION

Bird システムのデータベースオブジェクトとして, ユーザーの発言やフォロー,
フォロワー関係などの情報を保持します.
基本的にはサーバーオブジェクトの内部でデータを保存するためだけに使用されます. 

=head2 How to instantiate

インスタンス化は, クラスメソッド new を使うことで実行できます.

=cut

=head2 Public class methods

=over

=item My::Bird::OnMemoryDatabase->new()

My::Bird::OnMemoryDatabase オブジェクトを生成して返します.

=back

=cut

sub new {
    my $class = shift;
    my $self  = bless {
        "users"  => {},
        "tweets" => [],
    }, $class;
    return $self;
}

=head2 Public instance methods

=over

=item $db->add_user( $user_name )

$user_name で指定されたユーザー名のユーザーを新たに保持するようにします.
既に存在しているユーザー名が指定された場合は, 例外を発生させます.

=item $db->select_users( [ "user_names" => REF_TO_ARRAY, "limit" => REF_TO_ARRAY ] )

データベース内に存在するユーザーのユーザー名を返します. 
どのユーザーのユーザー名を返すかは, 引数で指定します. 
引数の連想配列の "user_names" は, ユーザー名を要素とする配列へのリファレンスを値とし, 
この値が存在する場合は, その配列に含まれているユーザー名のみを返り値に含みます. 
"limit" は, 値を 1 個か 2 個持つ配列へのリファレンスを値とし, 
この値が存在する場合は, 結果の絞込みを行います. "limit" の値が要素数 2 の場合, 
第 1 要素が絞り込み前の結果の先頭から何番目の値から絞り込むかを指定し, 
第 2 要素が絞込み後の個数を指定します. "limit" の値が要素数 1 の場合, 
要素数 2 の場合の先頭要素が 0 であるものとみませます. 
(分かりにくい説明ですが, 要は SQL の LIMIT 句と同じです.)

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=item $db->add_tweet( $user_name, $text )

$user_name で指定されたユーザー名のユーザーの発言として $text を登録します. 

=item $db->select_tweets( [ "user_names" => REF_TO_ARRAY, "limit" => REF_TO_ARRAY ] )

データベース内に存在する発言の情報を返します. 
どの発言情報を返すかは, 引数で指定します. 
引数の連想配列の "user_names" は, ユーザー名を要素とする配列へのリファレンスを値とし, 
この値が存在する場合は, その配列に含まれているユーザーの発言を返り値に含みます. 
"limit" は, select_users メソッドの場合と同様です. 

返り値は以下の構造を持つ配列へのリファレンスです. 

  [
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    { "user_name" => "発言したユーザーのユーザー名", "text" => "発言内容" },
    ...,
  ]

=item $db->create_following_relationship( $source_user_name, $target_user_name )

$source_user_name で指定されたユーザー名のユーザーが $target_user_name 
で指定されたユーザー名のユーザーをフォローしている状態にします. 

=item $db->select_followers( "user_name" => STRING, [ "limit" => REF_TO_ARRAY ] )

引数の連想配列の "user_name" で指定されたユーザーをフォローしているユーザーのユーザー名一覧を返します. 
"limit" は, select_users メソッドの場合と同様です. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=item $db->select_followings( "user_name" => STRING, [ "limit" => REF_TO_ARRAY ] )

引数の連想配列の "user_name" で指定されたユーザーがフォローしているユーザーのユーザー名一覧を返します. 
"limit" は, select_users メソッドの場合と同様です. 

返り値は, ユーザー名を要素とする配列へのリファレンスです. 

=back

=cut

sub add_user {
    my $self = shift;
    my $user_name = shift;
    die "user $user_name already exists" if defined $self->{"users"}{$user_name};
    $self->{"users"}{$user_name} = {
         "followings" => {},
         "followers"  => {},
    }
}

sub select_users {
    my $self = shift;
    my %cond = @_; # $cond{"user_names"}, $cond{"limit"}
    # 
    my @user_names = keys %{$self->{"users"}};
    # ユーザー名による絞込み
    if( defined $cond{"user_names"} ) {
        my %cc = map { ( $_, 1  ) } @{$cond{"user_names"}};
        @user_names = grep { defined $cc{$_} } @user_names;
    }
    # limit による絞込み
    if( defined $cond{"limit"} ) {
        $self->__limit( \@user_names, $cond{"limit"} );
    }
    return \@user_names;
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
    }
    @tweets = map { { %$_ } } @tweets;
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

