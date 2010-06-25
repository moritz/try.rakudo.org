#TODO: add error handling code where apropriate (create!)

package Session;

use strict;
use warnings;

use CGI;
use DBI;
use u64;

our $VERSION = '0.01';

use constant {
	DEFAULT_ID_MASK => u64::hex('5d422f795246703a'),
	DEFAULT_ID_SHIFT => 22
};

use constant {
	DEFAULT_FAIL_HEADERS => { -type=>'text/plain', -charset=>'utf-8' },
	DEFAULT_FAIL_FOOTER =>
		'Try again later or bug someone on #perl6 at irc.freenode.net'
};

use constant {
	EOK => 0,
	ECONNECT => 1,
	EDB => 2,
	EID => 3
};

use constant ERROR_STRINGS => (
	'no error',
	'connection failure',
	'database error',
	'illegal id'
);

sub new {
	my ($class, %hash) = @_;
	return bless(\%hash, $class)->initialize;
}

sub initialize {
	my $self = shift;

	$self->{errno} = EOK
		unless defined $self->{errno};

	$self->{strerror} = (ERROR_STRINGS)[$self->{errno}]
		unless defined $self->{strerror};

	$self->{logging} = 0
		unless defined $self->{logging};

	$self->{query} = CGI->new
		unless defined $self->{query};

	$self->{root} = $self->{query}->url(-base=>1)
		unless defined $self->{root};

	$self->{fail_footer} = DEFAULT_FAIL_FOOTER
		unless defined $self->{fail_footer};

	$self->{charset} = 'utf-8'
		unless defined $self->{charset};

	$self->{id_mask} = DEFAULT_ID_MASK
		unless defined $self->{id_mask};

	$self->{id_shift} = DEFAULT_ID_SHIFT
		unless defined $self->{id_shift};

	$self->{id} = $self->has_query_string ?
		$self->decode_id($ENV{QUERY_STRING}) : undef
		unless defined $self->{id};

	return $self;
}

sub log {
	my ($self, $msg) = @_;
	print STDERR $msg, "\n" if $self->{logging};
}

sub errno {
	my $self = shift;
	return $self->{errno};
}

sub strerror {
	my $self = shift;
	return $self->{strerror};
}

sub raise {
	my ($self, $errno, $msg) = @_;
	$self->{errno} = $errno;
	$self->{strerror} = (ERROR_STRINGS)[$errno].(defined $msg ? ': '.$msg : '');
	$self->log($self->{strerror});
	return undef;
}

sub has_id {
	my $self = shift;
	return defined $self->{id};
}

sub has_query_string {
	return length $ENV{QUERY_STRING} ? 1 : '';
}

sub root {
	my $self = shift;
	return $self->{root};
}

sub connect {
	my $self = shift;
	my $db = DBI->connect(@_)
		or return $self->raise(ECONNECT);

	$db->{AutoCommit} = 0;
	$db->{RaiseError} = 1;

	$self->{status_stmt} = $db->prepare(q{
		SELECT `status` FROM `Sessions`
		WHERE `id` = ? ;
	});

	$self->{create_stmt} = $db->prepare(q{
		INSERT INTO `Sessions` (
			`id`, `status`, `creation_time`, `last_access`)
		VALUES (
			NULL, 'u', NOW(), CURRENT_TIMESTAMP);
	});

	$self->{last_id_stmt} = $db->prepare(q{
		SELECT HEX(LAST_INSERT_ID());
	});

	$self->{access_stmt} = $db->prepare(q{
		UPDATE `Sessions`
		SET `last_access` = CURRENT_TIMESTAMP
		WHERE `id` = ? ;
	});

	$self->{db} = $db;
	return $self;
}

sub disconnect {
	my $self = shift;
	eval { $self->{db}->disconnect; };
}

sub status {
	my ($self, $update) = @_;
	return $self->{status} if not $update;

	my $access_stmt = $self->{access_stmt};
	my $status_stmt = $self->{status_stmt};
	my $status = undef;
	eval {
		$access_stmt->execute($self->{id});
		$status_stmt->execute($self->{id});
		$self->{db}->commit;
		$status_stmt->bind_col(1, \$status);
		$status_stmt->fetch;
	};

	$access_stmt->finish;
	$status_stmt->finish;

	my $error = $access_stmt->err or $status_stmt->err;
	return $self->raise(EDB, $error) if $error;
	return $self->raise(EID) if not defined $status;

	$self->{status} = $status;
	return $self->{status};
}

sub create {

	#TODO: error handling

	#TODO: add logic to get next free port
	#IDEA: just put the whole 64k port range into the DB

	my $self = shift;
	my $create_stmt = $self->{create_stmt};
	my $last_id_stmt = $self->{last_id_stmt};

	my $idstr = undef;
	eval {
		$create_stmt->execute();
		$last_id_stmt->execute();
		$self->{db}->commit;
		$last_id_stmt->bind_col(1, \$idstr);
		$last_id_stmt->fetch;
	};

	$create_stmt->finish;
	$last_id_stmt->finish;
	$self->log($create_stmt->err or $last_id_stmt->err or
		'create() returned no result')
		if not defined $idstr;

	$self->{id} = defined $idstr ? u64::hex($idstr) : undef;
	return $self->{id};
}

sub param {
	my $self = shift;
	return $self->{query}->param(@_);
}

sub header {
	my ($self, %args) = @_;
	$args{-charset} = $self->{charset};
	return $self->{query}->header(%args);
}

sub redirect {
	my ($self, $path) = @_;
	print $self->{query}->redirect(
		$self->{root}.$path.'?'.$self->encode_id($self->{id}));
}

sub decode_id {
	my ($self, $string) = @_;
	return undef if not $string =~ /^[0-9a-f]{16}$/;
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return u64::rot(u64::hex($string) ^ $mask, $shift);
}

sub encode_id {
	my ($self, $value) = @_;
	return undef if not u64::isa($value);
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return u64::lc(u64::rot($value, -$shift) ^ $mask);
}

sub fail {
	my ($self, $status, $msg, $footer, %headers) = @_;
	$self = { query=>CGI->new, fail_footer=>DEFAULT_FAIL_FOOTER }
		if not defined $self;
	$footer = $self->{fail_footer}
		if not defined $footer;

	print $self->{query}->header(
		-status=>$status, %{(DEFAULT_FAIL_HEADERS)}, %headers),
		$msg, "\n", $footer;
}

1;
