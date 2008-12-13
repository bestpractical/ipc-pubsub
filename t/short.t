use strict;
use warnings;
use Test::More;
use IPC::PubSub;
use IO::Socket::INET;
use File::Temp ':POSIX';

my @backends = qw(PlainHash);

unshift @backends, 'DBM_Deep' if eval { require DBM::Deep };
unshift @backends, 'JiftyDBI' if eval { require Jifty::DBI };
unshift @backends, 'Memcached' if eval { require Cache::Memcached } and IO::Socket::INET->new('127.0.0.1:11211');

plan tests => 2 * scalar @backends;

my $tmp = tmpnam();
END { unlink $tmp }

my %init_args = (
    DBM_Deep    => [ $tmp ],
    JiftyDBI    => [ db_init => 1 ],
    Memcached   => [ rand() . $$ ],
);

for my $backend (@backends) {
    diag("Testing backend $backend");
    local $TODO = "Removing a publisher removes their unseen messages";

    my $bus = IPC::PubSub->new( $backend, @{ $init_args{$backend} } );
    my $sub = $bus->new_subscriber( "brief" );
    {
        $bus->new_publisher( "brief" )->msg("ephemeral");
    }
    my @msgs = $sub->get;
    is_deeply(\@msgs, ["ephemeral"]);

    my $pub = $bus->new_publisher( "brief" );
    $pub->msg("will unsubscribe");
    $pub->unpublish("brief");
    @msgs = $sub->get;
    is_deeply(\@msgs, ["will unsubscribe"]);
}
