package IPC::PubSub::Cacheable;
use strict;
use Time::HiRes 'time';
use File::Spec;

#method fetch                (Str *@keys --> List of Pair)                   { ... }
#method store                (Str $key, Str $val, Num $time, Num $expiry)    { ... }

#method add_publisher        (Str $chan, Str $pub)                           { ... }
#method remove_publisher     (Str $chan, Str $pub)                           { ... }

#method get_index            (Str $chan, Str $pub --> Int)                   { ... }
#method set_index            (Str $chan, Str $pub, Int $index)               { ... }

#method publisher_indices    (Str $chan --> Hash of Int)                     { ... }

sub get {
    my ($self, $chan, $orig, $curr) = @_;

    no warnings 'uninitialized';
    sort { $a->[0] <=> $b->[0] } $self->fetch(
        map {
            my $pub = $_;
            my $index = $curr->{$pub};
            map {
                "$chan-$pub-$_"
            } (($orig->{$pub}+1) .. $index);
        } keys(%$curr)
    );
}

sub put {
    my ($self, $chan, $pub, $index, $msg, $expiry) = @_;
    $self->store("$chan-$pub-$index", $msg, time, $expiry);
    $self->set_index($chan, $pub, $index);
}


use constant LOCK => File::Spec->catdir(File::Spec->tmpdir, 'IPC::PubSub-lock-');

my %locks;
sub lock {
    my ($self, $chan) = @_;
    for my $i (1..10) {
        return if mkdir((LOCK . unpack("H*", $chan)), 0777);
        sleep 1;
    }
}

END {
    rmdir(LOCK . unpack("H*", $_)) for keys %locks;
}

sub unlock {
    my ($self, $chan) = @_;
    rmdir(LOCK . unpack("H*", $chan));
    delete $locks{$chan};
}

1;
