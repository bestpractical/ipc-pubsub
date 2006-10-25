package IPC::PubSub::Cache::JiftyDBI::Stash::Publisher;

use warnings;
use strict;

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column channel    => type is 'text';
    column name    => type is 'text';
    column idx => type is 'int';
};


package IPC::PubSub::Cache::JiftyDBI::Stash::PublisherCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab = $self->new_item->table();
    return $tab;
}

1;
