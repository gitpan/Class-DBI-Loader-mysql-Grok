use strict;
use warnings FATAL => 'all';

use DBI;

use Test::More;

BEGIN {
	eval "use DBD::mysql";
	plan $@ ? (skip_all => 'needs DBD::mysql for testing') : (tests => 9);
}


BEGIN { use_ok('Class::DBI::Loader::mysql::Grok') };

my $dbname	=  $ENV{DBD_MYSQL_DBNAME}	|| 'test';
my $db		= "dbi:mysql:$dbname";
my $user	=  $ENV{DBD_MYSQL_USER}		||'';
my $pass	=  $ENV{DBD_MYSQL_PASSWD}	||'';

# load the test db
my $output = qx( mysql $dbname < music.sql );


my $loader = Class::DBI::Loader->new(
	dsn             => $db,
	user            => $user,
	password        => $pass,
	options			=> {RaiseError=>1},
	constraint		=>	'^artist|cd|liner_notes|time_table|style|style_ref$',
	namespace       => "Music",
	relationships	=> 1,
#	debug			=> 1,
);

#$loader->db_Main->do(<<'') or die "Failed to create database tables: '$DBI::errstr'";

my $class  = $loader->find_class('cd'); # $class => Music::Cd
my $cd     = $class->retrieve(1);

# has_a
my $artist = $cd->artist;
ok($artist->name eq 'Apocryphal',"has_a: Music::Cd->artist");

# has_many
my($first_cd) = $cd->artist->cds;
ok($first_cd->title eq 'First',"has_many: Music::Artist->cds");

# might_have
ok($first_cd->notes eq 'Liner Notes for First',"might_have: Music::Cd->notes");

# time:
# datetime
my($tt) = $artist->time_tables;
ok($tt->datetime_field->ymd eq '2005-01-01',"Time::Piece: datetime");
ok($tt->date_field->ymd eq '2005-01-01',"Time::Piece: date");
ok($tt->time_field->hms eq '12:12:12',"Time::Piece: time");
ok($tt->timestamp_field->hms =~ /^\d\d:\d\d:\d\d$/,"Time::Piece: timestamp");

# style_ref: mapping
ok(($cd->styles) == 3,"has_many mapping: Music::Cd->styles");

qx( mysql $dbname < music_end.sql );

__END__




