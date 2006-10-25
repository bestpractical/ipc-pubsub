use strict;
use warnings;
use Test::More;
use IPC::PubSub;
use IO::Socket::INET;

my @backends = qw(PlainHash);

unshift @backends, 'DBM_Deep' if eval { require DBM::Deep };
unshift @backends, 'JiftyDBI' if eval { require Jifty::DBI };
unshift @backends, 'Memcached' if eval { require Cache::Memcached } and IO::Socket::INET->new('127.0.0.1:11211');

plan tests => 6 * scalar @backends;

SKIP: for my $backend (@backends) {
    my %init_args = ();
    diag('Testing backend '.$backend);
    if ($backend eq 'JiftyDBI') {
        $init_args{db_init} = 1;
    }

    my $bus = IPC::PubSub->new($backend, %init_args);

    my @sub; $sub[0] = $bus->new_subscriber;

    is_deeply([map {$_->[1]} @{$sub[0]->get_all->{''}}], [], 'get_all worked when there is no pubs');
    is_deeply([$sub[0]->get], [], 'get_all worked when there is no pubs');

    my $pub = $bus->new_publisher;

    $pub->msg('foo');

    $sub[1] = $bus->new_subscriber;

    $pub->msg(['bar', 'bar']);
    $pub->msg('baz');

    is_deeply([$sub[0]->get], ['foo', ['bar', 'bar'], 'baz'], 'get worked');
    is_deeply([$sub[0]->get], [], 'get emptied the cache');

    is_deeply([map {$_->[1]} @{$sub[1]->get_all->{''}}], [['bar', 'bar'], 'baz'], 'get_all worked');
    is_deeply([map {$_->[1]} @{$sub[1]->get_all->{''}}], [], 'get_all emptied the cache');
}
