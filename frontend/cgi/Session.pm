package Session;

use strict;
use warnings;

use CGI;
use DBI;
use u64;

our $VERSION = '0.01';

use constant ID_DEFAULT_MASK => u64::hex('5d422f795246703a');
use constant ID_DEFAULT_SHIFT => 22;

sub new {
	my ($class, %hash) = @_;
	return bless(\%hash, $class)->initialize;
}

sub initialize {
	my $self = shift;

	$self->{logging} = 0
		unless defined $self->{logging};

	$self->{id_mask} = ID_DEFAULT_MASK
		unless defined $self->{id_mask};

	$self->{id_shift} = ID_DEFAULT_SHIFT
		unless defined $self->{id_shift};

	$self->{query} = CGI->new
		unless defined $self->{query};

	$self->{id} = defined $ENV{QUERY_STRING} ?
		$self->decode_id($ENV{QUERY_STRING}) : undef
		unless defined $self->{id};

	$self->{root} = $self->{query}->url(-base=>1)
		unless defined $self->{root};

	return $self;
}

sub has_id {
	my $self = shift;
	return defined $self->{id};
}

sub connect {
	my $self = shift;
	my $db = DBI->connect(@_)
		or return undef;

	$db->{AutoCommit} = 0;
	$db->{RaiseError} = 1;

	$self->{status_stmt} = $db->prepare(q{
		SELECT `status` FROM `Sessions`
		WHERE `id` = ? ;
	});

	$self->{create_stmt} = $db->prepare(q{
		INSERT INTO `Sessions` (
			`id` , `status` , `creation_time` , `last_access`)
		VALUES (
			NULL , 'u', NOW() , CURRENT_TIMESTAMP);
	});

	$self->{last_id_stmt} = $db->prepare(q{
		SELECT LAST_INSERT_ID();
	});

	$self->{db} = $db;
	return $self;
}

sub disconnect {
	my $self = shift;
	eval { $self->{db}->disconnect; };
}

sub log {
	my $self = shift;
	my $msg = shift;
	print $msg, "\n" if $self->{logging};
}

sub status {
	my $self = shift;
	my $update = shift;
	return $self->{status} if not $update;

	my $stmt = $self->{status_stmt};
	my $status = eval {
		$stmt->execute($self->{id});
		$self->{db}->commit;
		$stmt->bind_col(1, \$self->{status});
		return $stmt->fetch ? $self->{status} : undef;
	};

	$stmt->finish;
	$self->log($stmt->err or 'status() returned no result')
		if not defined $status;

	return $status;
}

sub create {

	# TODO: add logic to get next free port
	# IDEA: just put the whole 64k port range into the DB
	# TODO: error handling: how to handle the case of no free port

	my $self = shift;
	my $create_stmt = $self->{create_stmt};
	my $last_id_stmt = $self->{last_id_stmt};

	my $id = eval {
		$create_stmt->execute();
		$last_id_stmt->execute();
		$self->{db}->commit;
		$last_id_stmt->bind_col(1, \$self->{id});
		return $last_id_stmt->fetch ? $self->{id} : undef;
	};

	$create_stmt->finish;
	$last_id_stmt->finish;
	$self->log($create_stmt->err or $last_id_stmt or
			'create() returned no result')
		if not defined $id;

	return $id;
}

sub param {
	my $self = shift;
	return $self->{query}->param(@_);
}

sub redirect {
	my ($self, $path) = @_;
	print $self->{query}->redirect(
		$self->{root}.$path.'?'.$self->encode_id($self->{id}));
}

sub decode_id {
	my ($self, $string) = @_;
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return undef if not $string =~ /^[0-9a-f]{16}$/;
	return u64::rot(u64::hex($string) ^ $mask, $shift);
}

sub encode_id {
	my ($self, $value) = @_;
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return u64::lc(u64::rot($value, -$shift) ^ $mask);
}

1;