#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'DBD::SQLite required for this test!' if $@;
plan tests => 12;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;
use DBD::SQLite;
use DBI;
use Try::Tiny;
use File::Temp qw(tmpnam);

my $dbname1 = tmpnam();
my $dbname2 = tmpnam();

plugin 'database', { 
    'databases' => {
        'dbone' =>  {
            'dsn'       => 'dbi:SQLite:dbname=' . $dbname1,
            'options'   => { RaiseError => 1, PrintError => 0 },
        },
        'dbtwo' => {
            'dsn'       => 'dbi:SQLite:dbname=' . $dbname2,
            'options'   => { RaiseError => 1, PrintError => 0 },
        },
    }
};

get '/create-table-one' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->dbone->do('CREATE TABLE foo ( bar INTEGER NOT NULL )');
    } catch {
        $r = 0;
    }; 
    $self->render(text => ($r) ? 'ok' : 'failed');
};

get '/drop-table-one' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->dbone->do('DROP TABLE foo');
    } catch {
        $r = 0;
    }; 
    $self->render(text => ($r) ? 'ok' : 'failed');
};

get '/create-table-two' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->dbtwo->do('CREATE TABLE foo ( bar INTEGER NOT NULL )');
    } catch {
        $r = 0;
    }; 
    $self->render(text => ($r) ? 'ok' : 'failed');
};

get '/drop-table-two' => sub {
    my $self = shift;
    my $r = 1;

    try {
        $self->dbtwo->do('DROP TABLE foo');
    } catch {
        $r = 0;
    }; 
    $self->render(text => ($r) ? 'ok' : 'failed');
};

my $t = Test::Mojo->new;

$t->get_ok('/create-table-one')->status_is(200)->content_is('ok');
$t->get_ok('/drop-table-one')->status_is(200)->content_is('ok');
$t->get_ok('/create-table-two')->status_is(200)->content_is('ok');
$t->get_ok('/drop-table-two')->status_is(200)->content_is('ok');

unlink($dbname1);
unlink($dbname2);
