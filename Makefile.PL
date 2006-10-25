use strict;
use inc::Module::Install;

name        'IPC-PubSub';
license     'MIT';
all_from    'lib/IPC/PubSub.pm';

requires    'DBM::Deep';
requires    'Data::UUID';
requires    'Class::Accessor::Fast';

sign; WriteAll;
