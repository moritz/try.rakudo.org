package u64;

use strict;
use warnings;

our $VERSION = '0.01';

use constant {
	INT64 => ~0 >= 2**64 - 1,
	POW32_M10 => 2**32 % 10
};

BEGIN {
	if(INT64) {
		*new = \&new_native;
		*hex = \&hex_native;
		*int = \&int_native;
		*uc = \&uc_native;
		*lc = \&lc_native;
		*isa = \&isa_native;
	}
	else {
		*new = \&new_virtual;
		*hex = \&hex_virtual;
		*int = \&int_virtual;
		*uc = \&uc_virtual;
		*lc = \&lc_virtual;
		*isa = \&isa_virtual;
	}
}

use overload
	'~' => \&bitwise_not,
	'|' => \&bitwise_or,
	'^' => \&bitwise_xor,
	'&' => \&bitwise_and,
	'<<' => \&bitshift_left,
	'>>' => \&bitshift_right,
	'""' => \&to_string,
	'0+' => \&to_number,
	'bool' => \&to_bool,
	'cos' => \&math_cos,
	'sin' => \&math_sin,
	'exp' => \&math_exp,
	'log' => \&math_log,
	'sqrt' => \&math_sqrt,
	'abs' => \&noop,
	'int' => \&lo;

my %exports = (
	u64 => \&new,
	hex64 => \&hex,
	int64 => \&int,
	uc64 => \&uc,
	lc64 => \&lc,
	rot64 => \&rot
);

sub import {
	no strict 'refs';
	shift();
	*{'::'.$_} = $exports{$_} for @_;
}

sub new_native { (shift() << 32) + shift() }
sub new_virtual { bless [@_] }
sub hi { shift()->[0] }
sub lo { shift()->[1] }
sub noop { shift() }

sub isa_native {
	my $value = shift;
	defined $value and u64::int($value) == $value;
}

sub isa_virtual {
	my $value = shift;
	defined $value and UNIVERSAL::isa($value, 'u64');
}

sub hex_native {
	no warnings qw(portable);
	@_ = shift() =~ /^(?:0x)?([0-9a-f]{0,16})$/i;
	@_ ? CORE::hex shift() : undef;
}

sub hex_virtual {
	@_ = shift() =~ /^(?:0x)?([0-9a-f]{0,8}?)([0-9a-f]{0,8})$/i;
	@_ ? new(CORE::hex shift(), CORE::hex shift()) : undef;
}

sub int_native {
	CORE::int((shift() % 2**64 + 2**64) % 2**64)
}

sub int_virtual {
	my $value = shift();
	if(u64::isa($value)) { $value }
	else {
		my $hi = CORE::int((($value / 2**32) % 2**32 + 2**32) % 2**32);
		my $lo = CORE::int((($value % 2**32) + 2**32) % 2**32);
		new($hi, $lo);
	}
}

sub uc_native {
	my $value = shift();
	my $format = shift() ? '%016X' : '%X';
	sprintf $format, $value;
}

sub uc_virtual {
	my ($hi, $lo) = @{shift()};
	if(shift()) { sprintf '%08X%08X', $hi, $lo }
	elsif($hi) { sprintf '%X%08X', $hi, $lo }
	else { sprintf '%X', $lo }
}

sub lc_native {
	my $value = shift();
	my $format = shift() ? '%016x' : '%x';
	sprintf $format, $value;
}

sub lc_virtual {
	my ($hi, $lo) = @{shift()};
	if(shift()) { sprintf '%08x%08x', $hi, $lo }
	elsif($hi) { sprintf '%x%08x', $hi, $lo }
	else { sprintf '%x', $lo }
}

sub rot {
	my ($value, $count) = (shift(), CORE::int(shift()) % 64);
	if($count < 0) { $value >> -$count | $value << (64 + $count) }
	else { $value << $count | $value >> (64 - $count) }
}

sub bitwise_not {
	my $value = shift();
	new(~$value->hi, ~$value->lo);
}

sub bitwise_or {
	my ($a, $b) = @_;
	u64::isa($b) ?
		new($a->hi | $b->hi, $a->lo | $b->lo) :
		new($a->hi, $a->lo | $b);
}

sub bitwise_xor {
	my ($a, $b) = @_;
	u64::isa($b) ?
		new($a->hi ^ $b->hi, $a->lo ^ $b->lo) :
		new($a->hi, $a->lo ^ $b);
}

sub bitwise_and {
	my ($a, $b) = @_;
	u64::isa($b) ?
		new($a->hi & $b->hi, $a->lo & $b->lo) :
		new(0, $a->lo & $b);
}

sub bitshift_left {
	my $reversed = $_[2];
	if($reversed) {
		my ($b, $a) = (CORE::int(shift()), shift());
		$a << $b;
	}
	else {
		my ($a, $b) = (shift(), CORE::int(shift()));
		if($b <= 0) { $a }
		elsif($b < 32) {
			new($a->hi << $b | $a->lo >> (32 - $b), $a->lo << $b)
		}
		else { new($a->lo, 0) << ($b - 32) }
	}
}

sub bitshift_right {
	my $reversed = $_[2];
	if($reversed) {
		my ($b, $a) = (CORE::int(shift()), shift());
		$a >> $b;
	}
	else {
		my ($a, $b) = (shift(), CORE::int(shift()));
		if($b <= 0) { $a }
		elsif($b < 32) {
			new($a->hi >> $b, $a->lo >> $b | $a->hi << (32 - $b))
		}
		else { new(0, $a->hi) >> ($b - 32) }
	}
}

sub math_cos { cos shift()->to_number }
sub math_sin { sin shift()->to_number }
sub math_exp { exp shift()->to_number }
sub math_log { log shift()->to_number }
sub math_sqrt { sqrt shift()->to_number }

sub to_dec {
	my ($hi, $lo) = @{shift()};
	my $str = '';
	while($hi or $lo) {
		my $hi_m10 = $hi % 10;
		my $lo_m10 = $lo % 10;
		my $x = ($hi_m10 * POW32_M10) % 10 + $lo_m10;
		my $x_m10 = $x % 10;
		$str .= $x_m10;
		$hi = ($hi - $hi_m10) / 10;
		$lo = ($lo - $lo_m10) / 10 + ($x - $x_m10) / 10 +
			CORE::int(($hi_m10 * 2**32) / 10);
	}
	reverse $str;
}

sub to_string {
	my $value = shift();
	$value->hi ? $value->to_dec : ''.$value->lo;
}

sub to_number {
	my $value = shift();
	$value->hi * 2**32 + value->lo;
}

sub to_bool {
	my $value = shift();
	($value->hi or $value->lo) ? 1 : '';
}

1;
