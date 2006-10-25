package IPC::PubSub::Cache::JiftyDBI::Stash::Item;

use warnings;
use strict;

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column key    => type is 'text';
    column val    => type is 'blob', filters are 'Jifty::DBI::Filter::Storable';
    column expiry => type is 'int';
};

package IPC::PubSub::Cache::JiftyDBI::Stash::ItemCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab = $self->new_item->table();
    return $tab;
}


1;
