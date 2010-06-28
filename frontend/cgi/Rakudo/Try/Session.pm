#NOTE: uses MySQL-specific features
#TODO: backend interaction

package Rakudo::Try::Session;

use strict;
use warnings;

use CGI;
use DBI;

our $VERSION = '0.01';

sub import {
	no strict 'refs';
	my $caller = caller;
	*{$caller.'::Session_PROTO'} = \&PROTO;
	*{$caller.'::Session_ECONNECT'} = \&ECONNECT;
	*{$caller.'::Session_EDB'} = \&EDB;
	*{$caller.'::Session_EID'} = \&EID;
	*{$caller.'::Session_EUNKNOWN'} = \&EUNKNOWN;
	*{$caller.'::Session_ESTATE'} = \&ESTATE;
}

sub ECONNECT	{ 1 }
sub EDB			{ 2 }
sub EID			{ 3 }
sub EUNKNOWN	{ 4 }
sub ESTATE		{ 5 }

use constant DB_FLAGS => (
	RaiseError => 1,
	PrintError => 0,
	AutoCommit => 0
);

use constant {
	ID_SHIFT_HI => 5,
	ID_SHIFT_LO => 15,
	ID_MASK_HI => 0x2521D99F,
	ID_MASK_LO => 0xD25958F4
};

my $proto = bless {
	id => undef,
	query => undef,
	root => undef,
	db => undef,
	status => undef,
	errno => 0,
	charset => 'utf-8',
	id_encoder => sub {
		my $_ = shift;
		my $len = length $_;
		$_ = (substr '0000000000000000', 0, 16 - $len).$_
			if(length $_ < 16);
		/^([0-9a-fA-F]{8})([0-9a-fA-F]{8})$/ or return undef;
		my $hi = hex substr($_, 0, 8);
		my $lo = hex substr($_, 8, 8);
		$hi = $hi << ID_SHIFT_HI | $hi >> (32 - ID_SHIFT_HI);
		$lo = $lo >> ID_SHIFT_LO | $lo << (32 - ID_SHIFT_LO);
		$hi = ($hi & 0xFFFFFFFF) ^ ID_MASK_HI;
		$lo = ($lo & 0xFFFFFFFF) ^ ID_MASK_LO;
		return sprintf '%08x%08x', $hi, $lo;
	},
	id_decoder => sub {
		my $_ = shift;
		/^([0-9a-f]{8})([0-9a-f]{8})$/ or return undef;
		my $hi = hex substr($_, 0, 8);
		my $lo = hex substr($_, 8, 8);
		$hi = $hi ^ ID_MASK_HI;
		$lo = $lo ^ ID_MASK_LO;
		$hi = ($hi >> ID_SHIFT_HI | $hi << (32 - ID_SHIFT_HI)) & 0xFFFFFFFF;
		$lo = ($lo << ID_SHIFT_LO | $lo >> (32 - ID_SHIFT_LO)) & 0xFFFFFFFF;
		return $hi ? sprintf '%x%08x', $hi, $lo : sprintf '%x', $lo;
	}
};

sub PROTO { $proto }

sub clone {
	my ($self, %args) = @_;
	my %clone = %$self;
	@clone{keys %args} = values %args;
	return bless \%clone;
}

sub init {
	my $self = shift;

	$self->{query} = CGI->new
		if not defined $self->{query};

	$self->{root} = $self->{query}->url(-base => 1)
		if not defined $self->{root};

	$self->{id} =
		(&{$self->{id_decoder}}($ENV{QUERY_STRING}) or $self->raise(EID))
		if (not defined $self->{id} and defined $ENV{QUERY_STRING}
			and length $ENV{QUERY_STRING});

	return $self;
}

sub root { shift->{root} }

sub param { shift->{query}->param(@_) }

sub has_id { defined shift->{id} }

sub id {
	my $self = shift;
	return &{$self->{id_encoder}}($self->{id});
}

sub errno : lvalue { shift->{errno} }

sub raise {
	my ($self, $errno) = @_;
	$self->{errno} = $errno;
	return undef;
}

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

sub connect {
	my ($self, $source, $user, $pass, %args) = @_;
	my %flags = DB_FLAGS;
	@flags{keys %args} = values %args;

	my $db = eval { DBI->connect($source, $user, $pass, \%flags) }
		or return $self->raise(ECONNECT);
	$self->{db} = $db;

	my %statements;
	eval {
		$statements{select_status} = $db->prepare(q{
			SELECT `status` FROM `sessions`
			WHERE `id` = CONV( ?, 16, 10 )
		});

		$statements{insert_session} = $db->prepare(q{
			INSERT INTO `sessions` (
				`id`, `status`, `creation_time`, `last_access` )
			VALUES ( NULL, 'u', NOW(), CURRENT_TIMESTAMP )
		});

		$statements{select_last_id} = $db->prepare(q{
			SELECT CONV( LAST_INSERT_ID(), 10, 16 )
		});

		$statements{update_access} = $db->prepare(q{
			UPDATE `sessions`
			SET `last_access` = CURRENT_TIMESTAMP
			WHERE `id` = CONV( ? , 16, 10 )
		});

		$statements{select_messages} = $db->prepare(q{
			SELECT `contents`, 'type' FROM `messages`
			WHERE `session_id` = CONV( ?, 16, 10 ) AND `sequence_number` >= ?
			ORDER BY `sequence_number`
		});

		return 1;
	} or return $self->raise(EDB);
	$self->{statements} = \%statements;

	return $self;
}

sub disconnect {
	my $db = shift->{db};
	return if not defined $db;
	eval { $db->rollback };
	eval { $db->disconnect } or warn $db->errstr;
}

sub status {
	my ($self, $update) = @_;
	return $self->{status} if not $update;

	my $update_access = $self->{statements}->{update_access};
	my $select_status = $self->{statements}->{select_status};

	my $status = undef;
	eval {
		$update_access->execute($self->{id});
		$select_status->execute($self->{id});
		$self->{db}->commit;
		$select_status->bind_col(1, \$status);
		$select_status->fetch;
		$select_status->finish;
		return 1;
	} or return $self->raise(EDB);

	return $self->raise(EUNKNOWN) if not defined $status;
	return $self->{status} = $status;
}

sub create {
	my $self = shift;
	my $insert_session = $self->{statements}->{insert_session};
	my $select_last_id = $self->{statements}->{select_last_id};

	my $id = undef;
	eval {
		$insert_session->execute;
		$select_last_id->execute;
		$self->{db}->commit;
		$select_last_id->bind_col(1, \$id);
		$select_last_id->fetch;
		$select_last_id->finish;
		return defined $id;
	} or return $self->raise(EDB);

	return $self->{id} = $id;
}

sub load_messages {
	my ($self, $seq_num, $contents_ref, $type_ref) = @_;
	my $select_messages = $self->{statements}->{select_messages};

	return (eval {
		$select_messages->execute($self->{id}, $seq_num);
		$select_messages->bind_col(1, $contents_ref)
			if defined $contents_ref;
		$select_messages->bind_col(2, $type_ref)
			if defined $type_ref;
		return 1;
	} or $self->raise(EDB));
}

sub unload_messages {
	# don't raise EDB as execution is finished
	my $select_messages = shift->{statements}->{select_messages};
	eval { $select_messages->finish } or warn $select_messages->errstr;
}

sub next_message {
	my $self = shift;
	my $res = undef;
	eval {
		$res = $self->{statements}->{select_messages}->fetch;
		return 1;
	} or return $self->raise(EDB);
	return $res;
}

1;
