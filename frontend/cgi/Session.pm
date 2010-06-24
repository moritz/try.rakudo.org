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

	$self->{id_mask} = ID_DEFAULT_MASK
		unless defined $self->{id_mask};

	$self->{id_shift} = ID_DEFAULT_SHIFT
		unless defined $self->{id_shift};

	$self->{query} = CGI->new
		unless defined $self->{query};

	$self->{id} = defined $ENV{QUERY_STRING} ?
		$self->decode_id($ENV{QUERY_STRING}) : 0
		unless defined $self->{id};

	return $self;
}

sub id {
	my $self = shift;
	return $self->{id};
}

sub connect {
	my $self = shift;
	my $db = DBI->connect(@_)
		or return undef;
	$db->{AutoCommit} = 0;
	$db->{RaiseError} = 1;
	$self->{db} = $db;
	return $self;
}

sub disconnect {
	my $self = shift;
	eval { $self->{db}->disconnect; }
}

sub param {
	my $self = shift;
	return $self->{query}->param(@_);
}

sub decode_id {
	my ($self, $string) = @_;
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return u64::rot(u64::hex($string), $shift) ^ $mask;
}

sub encode_id {
	my ($self, $value) = @_;
	my ($mask, $shift) = @$self{'id_mask', 'id_shift'};
	return u64::lc(u64::rot($value, -$shift) ^ $mask);
}

1;