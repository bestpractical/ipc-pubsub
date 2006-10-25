package IPC::PubSub::Cache::Memcached;
use strict;
use base 'IPC::PubSub::Cacheable';
use Cache::Memcached;

sub new {
    my $class = shift;
    my $config = shift || $class->default_config;
    my $mem = Cache::Memcached->new($config);
    bless(\$mem, $class);
}

sub default_config {
    return {
        servers => ['127.0.0.1:11211'],
        debug => 0
    };
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
    $$self->get("$chan#") || {};
}

sub lock {
    my ($self, $chan) = @_;
    for my $i (1..10) {
        return if $$self->add("$chan#lock" => 1);
        sleep 1;
    }
}

sub unlock {
    my ($self, $chan) = @_;
    $$self->delete("$chan#lock");
}

sub add_publisher {
    my ($self, $chan, $pub) = @_;
    $self->lock($chan);
    my $pubs = $$self->get("$chan#") || {};
    $pubs->{$pub} = 0;
    $$self->set("$chan#", $pubs);
    $self->unlock($chan);
}

sub remove_publisher {
    my ($self, $chan, $pub) = @_;
    $self->lock($chan);
    my $pubs = $$self->get("$chan#") || {};
    delete $pubs->{$pub};
    $$self->set("$chan#", $pubs);
    $self->unlock($chan);
}

sub get_index {
    my ($self, $chan, $pub) = @_;
    ($$self->get("$chan#") || {})->{$pub};
}

sub set_index {
    my ($self, $chan, $pub, $idx) = @_;
    my $pubs = $$self->get("$chan#") || {};
    $pubs->{$pub} = $idx;
    $$self->set("$chan#", $pubs);
}

1;
