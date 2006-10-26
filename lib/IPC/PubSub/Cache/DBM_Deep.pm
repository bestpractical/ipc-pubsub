package IPC::PubSub::Cache::DBM_Deep;
use strict;
use base 'IPC::PubSub::Cache';
use DBM::Deep;
use File::Temp qw/ tempfile /;

sub new {
    my $class = shift;
    my $file  = shift;
    my $mem = DBM::Deep->new($file || $class->default_config);
    bless(\$mem, $class);
}

sub default_config {
    my (undef, $filename) = tempfile(UNLINK => 1);
    return $filename;
}

sub fetch {
    my $self = shift;
    map { $$self->get($_) } @_;
}

sub store {
    my ($self, $key, $val, $time, $expiry) = @_;
    $$self->put($key, [$time, $val]);
}

sub publisher_indices {
    my ($self, $chan) = @_;
    return { %{ $$self->get("$chan#") || {} } };
}

sub add_publisher {
    my ($self, $chan, $pub) = @_;
    my $pubs = { %{ $$self->get("$chan#") || {} } };
    $pubs->{$pub} = 0;
    $$self->put("$chan#", $pubs);
}

sub remove_publisher {
    my ($self, $chan, $pub) = @_;
    my $pubs = { %{ $$self->get("$chan#") || {} } };
    delete $pubs->{$pub};
    $$self->put("$chan#", $pubs);
}

sub get_index {
    my ($self, $chan, $pub) = @_;
    ($$self->get("$chan#") || {})->{$pub};
}

sub set_index {
    my ($self, $chan, $pub, $idx) = @_;
    my $pubs = { %{ $$self->get("$chan#") || {} } };
    $pubs->{$pub} = $idx;
    $$self->put("$chan#", $pubs);
}

1;
