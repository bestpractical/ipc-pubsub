package IPC::PubSub::Cache::Memcached;
use strict;
use warnings;
use base 'IPC::PubSub::Cache';
use Cache::Memcached;
use Time::HiRes ();

sub new {
    my $class       = shift;
    my $namespace   = shift || $class;
    my $config      = shift || $class->default_config($namespace);
    my $mem = Cache::Memcached->new($config);
    bless(\$mem, $class);
}

sub disconnect {
    my $self = shift;
    $$self->disconnect_all;
}

sub default_config {
    my ($class, $namespace) = @_;
    return {
        servers     => ['127.0.0.1:11211'],
        debug       => 0,
        namespace   => $namespace,
    };
}

sub fetch_data {
    my $self = shift;
    my $key  = shift;
    return $$self->get("data:$key");
}

sub store_data {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    if (defined $val) {
        $$self->set("data:$key" => $val);
    }
    else {
        $$self->delete("data:$key");
    }
}

sub fetch {
    my $self = shift;
    values(%{$$self->get_multi(@_)});
}

sub store {
    my ($self, $key, $val, $time, $expiry) = @_;
    $$self->set($key, [$time, $val], $expiry);
}

sub publisher_indices {
    my ($self, $chan) = @_;
    $$self->get("pubs:$chan") || {};
}

sub lock {
    my ($self, $key) = @_;
    for my $i (1..100) {
        return if $$self->add("lock:$key" => 1);
        Time::HiRes::usleep(rand(250000)+250000);
    }
}

sub unlock {
    my ($self, $chan) = @_;
    $$self->delete("lock:$chan");
}

sub add_publisher {
    my ($self, $chan, $pub) = @_;
    my $key = "pubs:$chan";
    $self->lock($key);
    my $pubs = $$self->get($key) || {};
    $pubs->{$pub} = 0;
    $$self->set($key => $pubs);
    $self->unlock($key);
}

sub remove_publisher {
    my ($self, $chan, $pub) = @_;
    my $key = "pubs:$chan";
    $self->lock($key);
    my $pubs = $$self->get($key) || {};
    delete $pubs->{$pub};
    $$self->set($key => $pubs);
    $self->unlock($key);
}

sub get_index {
    my ($self, $chan, $pub) = @_;
    ($$self->get("pubs:$chan") || {})->{$pub};
}

sub set_index {
    my ($self, $chan, $pub, $idx) = @_;
    my $pubs = $$self->get("pubs:$chan") || {};
    $pubs->{$pub} = $idx;
    $$self->set("pubs:$chan", $pubs);
}

1;
