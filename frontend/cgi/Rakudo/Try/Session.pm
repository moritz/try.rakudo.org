package Rakudo::Try::Session;

use strict;
use warnings;

use CGI;
use DBI;

our $VERSION = '0.01';

# --- error constants ---

sub EOK 		{ 0 }
sub ECONNECT	{ 1 }
sub EDB			{ 2 }
sub EID			{ 3 }
sub EUNKNOWN	{ 4 }
sub ESTATE		{ 5 }

# --- DB flags ---

use constant DB_FLAGS => (
	RaiseError => 1,
	PrintError => 0,
	AutoCommit => 0
);

# --- id mangling ---

use constant {
	ID_SHIFT_HI => 5,
	ID_SHIFT_LO => 15,
	ID_MASK_HI => 0x2521D99F,
	ID_MASK_LO => 0xD25958F4
};

my $id_encoder = sub {
	my $_ = shift;
	/^([0-9a-f]{8})([0-9a-f]{8})$/ or return undef;
	my $hi = hex substr($_, 0, 8);
	my $lo = hex substr($_, 8, 8);
	$hi = $hi << ID_SHIFT_HI | $hi >> (32 - ID_SHIFT_HI);
	$lo = $lo >> ID_SHIFT_LO | $lo << (32 - ID_SHIFT_LO);
	$hi = ($hi & 0xFFFFFFFF) ^ ID_MASK_HI;
	$lo = ($lo & 0xFFFFFFFF) ^ ID_MASK_LO;
	return sprintf '%08x%08x', $hi, $lo;
};

my $id_decoder = sub {
	my $_ = shift;
	/^([0-9a-f]{8})([0-9a-f]{8})$/ or return undef;
	my $hi = hex substr($_, 0, 8);
	my $lo = hex substr($_, 8, 8);
	$hi = $hi ^ ID_MASK_HI;
	$lo = $hi ^ ID_MASK_LO;
	$hi = ($hi >> ID_SHIFT_HI | $hi << (32 - ID_SHIFT_HI)) & 0xFFFFFFFF;
	$lo = ($lo << ID_SHIFT_LO | $lo >> (32 - ID_SHIFT_LO)) & 0xFFFFFFFF;
	return sprintf '%08x%08x', $hi, $lo;
};

# --- session prototype ---

my $proto = bless {
	errno => EOK,
	charset => 'utf-8',
	id_encoder => $id_encoder,
	id_decoder => $id_decoder,
	id => undef,
	query => undef,
	root => undef,
	db => undef
};

sub PROTO { $proto }

# --- module setup ---

sub import {
	no strict 'refs';
	my $caller = caller;
	*{$caller.'::Session_PROTO'} = \&PROTO;
	*{$caller.'::Session_EOK'} = \&EOK;
	*{$caller.'::Session_ECONNECT'} = \&ECONNECT;
	*{$caller.'::Session_EDB'} = \&EDB;
	*{$caller.'::Session_EID'} = \&EID;
	*{$caller.'::Session_EUNKNOWN'} = \&EUNKNOWN;
	*{$caller.'::Session_ESTATE'} = \&ESTATE;
}

# --- object infrastructure ---

sub clone {
	my ($self, %args) = @_;
	my %clone = %$self;
	@clone{keys %args} = values %args;
	return bless \%clone;
}

sub init {
	my $self = shift;
	$self->{query} = CGI->new;
	$self->{root} = $self->{query}->url(-base => 1);
	$self->{id} =
		(&self->{id_decoder}($ENV{QUERY_STRING}) or $self->raise(EID))
		if (defined $ENV{QUERY_STRING} and length $ENV{QUERY_STRING});
	return $self;
}

# --- public fields ---

sub root { shift->{root} }

sub param { shift->{query}->param(@_) }

sub has_id { defined shift->{id} }

sub id {
	my $self = shift;
	return &self->{id_encoder}($self->{id});
}

# --- error handling ---

sub errno : lvalue { shift->{errno} }

sub raise {
	my ($self, $errno) = @_;
	$self->{errno} = $errno;
	return undef;
}

# --- HTTP output ---

sub send_headers {
	my ($self, $status, %headers) = @_;
	print $self->{query}->header(
		-status => $status, -charset => $self->{charset}, %headers);
}

sub send_response {
	my $body = splice @_, 2, 1;
	send_headers(@_);
	print $body if defined $body;
}

sub redirect {
	my ($self, $path) = @_;
	print $self->{query}->redirect($self->{root}.$path.'?'.$self->id);
	exit;
}

sub die {
	send_response(@_, -type => 'text/plain');
	exit;
}

# --- DB infrastructure ---

sub connect {
	my ($self, $source, $user, $pass, %args) = @_;
	my %flags = DB_FLAGS;
	@flags{keys %args} = values %args;
	my $db = eval { DBI->connect($source, $user, $pass, \%flags) };
	return $self->raise(ECONNECT) if not defined $db;

###TODO: create + bind statements

	$self->{db} = $db;
	return $self;
}

sub disconnect {
	my $db = shift->{db};
	return if not defined $db;
	eval { $db->rollback };
	eval { $db->disconnect } or warn $db->errstr;
}

# --- data manipulation ---

sub create {}

1;
