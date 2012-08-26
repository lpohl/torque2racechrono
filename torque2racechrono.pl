#!/usr/bin/perl -w
#
# 	Converts a Torque Logfile to a RaceChrono2avi Suiteable csv File
#
#	This Code is far from automagic or perfect, if you use it, 
#	you will probaly have to beat it like Stick to get what you want.
# 	
#
#	Licence?
#	GPL or for the lulz
#

use strict;

my $in = $ARGV[0] or die "need input file!\n";
my $out = $ARGV[1] or die "need output file!\n" ;

sub f2c;
sub ts2ds;
sub rchead;
sub acos;
sub rad;
sub dist;
sub getTrapName;

my @rows;
my @rc;
open(IN, "<:encoding(utf8)", $in) or die "$in $!";
while (<IN>) {
	chomp($_);
	push @rows, $_;
}
close (IN);

open(OUTPUT, ">:encoding(utf8)", $out) or die "$out: $!";
print OUTPUT rchead();

# n=1 skip header line on input file
for(my $n=1; $n<$#rows; $n++) {
	my @V = split (/,/, $rows[$n]);	# Torque TrackLog input ATTENTION You need to modify
	my @RC = (); 					# Representing one RaceChrono type Line
	# @RS RaceChrono 
	# @V torque
	#         Values+Convert    # RaceChrono Fieldnames
	$RC[0]  = 1;				# LAP #
	$RC[1]  = ts2ds($V[1]);		# Timestamp (s)
	$RC[2]  = $V[29]*1000;		# Distance (m)
	$RC[3]  = $V[29];			# Distance (km)
	$RC[4]  = $V[25];			# Locked satellites
	$RC[5]  = $V[3];			# Latitude (deg)
	$RC[6]  = $V[2];			# Longitude (deg)
	$RC[7]  = $V[12]/3.6;		# Speed (m/s)
	$RC[8]  = $V[12];			# Speed (kph) 
	$RC[9]  = $V[12]/1.609344;	# Speed (mph)
	$RC[10] = $V[27];			# Altitude (m)
	$RC[11] = $V[26];			# Bearing (deg)
	$RC[12] = $V[10];			# Longitudinal Acceleration (G)
	$RC[13] = $V[8];			# Lateral Acceleration (G)
	
	# Converting GPS Coordinates to distances and X/Y Coordonates to a center of the Track (nordschleife)
	my $la = $V[3]; # Y
	my $lo = $V[2]; # X
	my $xv = "+"; my $yv = "+";
	if ($la < 50.3598222222) { $yv = "-";}
	if ($lo < 6.9658444444) { $xv = "-"; }
	$RC[14] = "$xv".dist(50.3598222222, $lo);	# X-position (m) 
	$RC[15] = "$yv".dist($la, 6.9658444444);	# Y-position (m) 
	# Debug
	#print "la: $la lo: $lo\n";
	#print "dia: ".dist($la,$lo)."\n";
	#print "x:  $xv".dist(50.3598222222,$lo)."\n";
	#print "y:  $yv".dist($la,6.9658444444)."\n";
	
	$RC[16] = $V[16];			# RPM (rpm)
	$RC[17] = 0;				# Throttle Position (%)
	$RC[18] = getTrapName($la,$lo);				# Trapname
	
	# Output new RC Type order and values
	print OUTPUT join(',', @RC);
	print OUTPUT "\r\n";
}
close(OUTPUT);

exit 0;

#
# SUBS
#

#  Fahrenheit in Celsius = ( TFahrenheit - 32 ) × 5 / 9
sub f2c {	
	my $f = shift;
	my $c = $f - 32;
	print "f:$f c:$c\n";
	my $x = $c * 5/9;
	print "$x\n";
	return $x;
}

# timestamp to daystamp
# input 21-Aug-2012 18:18:21.647
# output 65901.647
#
sub ts2ds {
        my $in = shift;
        my ($date, $time) = split(/ /, $in);
        my ($h,$m,$s) = split(/:/, $time);
        $m *= 60;
        $h *= 3600;
        my $x = $h + $m + $s;
}

sub getTrapName {
	my $la = shift;
	my $lo = shift;
	my $str = "$la,$lo";
	
	my %TN = (	'Entrance Touristenfahrt'			=> "50.345.*,6.964",
				'Start Clock(Bridge)Antoniusbuche'  => "50.343.*,6.960",
				'1 km Tiergarten' 					=> "50.340.*,6.955",
				'2 km Hatzenbach' 					=> "50.337.*,6.945",
				'3 km Hocheichen' 					=> "50.340.*,6.934",
				'4 km Flugplatz'  					=> "50.346.*,6.925",
				'5 km Schwedenkreuz' 				=> "50.355.*,6.924",
				'6 km Fuchsroehre' 					=> "50.360.*,6.925",
				'7 km Adenauer-Forst' 				=> "50.367.*,6.932",
				'8 km Metzgesfeld' 					=> "50.373.*,6.934",
				'9 km Wehrseifen' 					=> "50.376.*,6.942",
				'10 km Lauda-Linksknick' 			=> "50.379.*,6.954",
				'11 km Bergwerk' 					=> "50.377.*,6.961",
				'12 km Kesselchen' 					=> "50.374.*,6.972",
				'13 km Klostertal' 					=> "50.374.*,6.984",
				'14 km Caracciola-Karusell' 		=> "50.372.*,6.988",
				'15 km Hohe Acht' 					=> "50.376.*,6.997",
				'16 km Bruennchen' 					=> "50.370.*,7.005",
				'17 km Pflanzgarten 1' 				=> "50.364.*,6.999",
				'18 km Pflanzgarten 2' 				=> "50.358.*,6.991",
				'19 km Schwalbenschwanz' 			=> "50.356.*,6.983",
				'Finish(Gantry)Doettinger-Hoehe' 	=> "50.351.*,6.980"
				);
	foreach my $key (keys(%TN)) {
		if ( $str =~ /$TN{$key}/ ) {
			return $key;
		}
	}
	return "";
}

sub rchead {

my $head = 	"This file is created using Crazys Torque2RaceChrono Converter v0.01\r\n".
			"Session title,Nuerburgring\r\n".
			"Session type,Lap timing\r\n".
			"Track name,Nordschleife_BtG\r\n".
			"Driver name,Crazy\r\n".
			"Export scope,All laps\r\n".
			"Created,21/08/2012,18:17:00\r\n".
			"Note\r\n".
			"\t\r\n".
			"Lap #,Timestamp (s),Distance (m),Distance (km),Locked satellites,Latitude (deg),Longitude (deg),Speed (m/s),Speed (kph),Speed (mph),Altitude (m),Bearing (deg),Longitudinal Acceleration (G),Lateral Acceleration (G),X-position (m),Y-position (m),RPM (rpm),Throttle Position (%),Trap name\r\n";
return $head;
}

#
# Found most usefull websites with perl fuctions for Latitude & Longitude calculations:
#
# http://www.movable-type.co.uk/scripts/latlong.html
# http://jan.ucc.nau.edu/~cvm/latlon_formula.html
#
# subroutine acos
#
# input: an angle in radians
#
# output: returns the arc cosine of the angle
#
# description: this is needed because perl does not provide an arc cosine function

sub acos {
   my($x) = @_;
   my $ret = atan2(sqrt(1 - $x**2), $x);
   return $ret;
}

#
# subroutine dist 
# 
#  input 1: 	latitude coordinates in degree
#  input 2: 	longitude coordinates in degree
#  opt input 3:	latitude coordinates in degree (reference point)
#  opt input 4:	latitude coordinates in degree (reference point)
#  opt input 5: Radius default set to Earth Radius in m you could use 6378km or 
#
sub dist {
	my $dLat = shift;
	my $dLon = shift;
	
	my $dLa1 = shift || undef;
	my $dLo1 = shift || undef;
	my $r    = shift || 6378000; # earth Radius in m
	
	# cordinates in radiant values
	my ($la1,$lo1, $la2,$lo2);
	# Setting reference coordinates
	# Converting to radiant values
	# 
	# Default reference Point is the center of the "Nordschleife"
	# 50.3598222222,6.9658444444
	
	# Setting actual Coordinates
	$dLa1 = 50.3598222222 unless $dLa1;
	$dLo1 = 6.9658444444 unless $dLo1;
	$la1 = rad($dLa1);
	$lo1 = rad($dLo1);

	$la2 = rad($dLat);
	$lo2 = rad($dLon);
	
	# Calculating distance between reference point and actual point
	my $dist = acos(sin($la1)*sin($la2) + cos($la1)*cos($la2)*cos($lo2-$lo1)) * $r;

	return $dist;
}

sub rad {
        my $deg = shift;
        my $pi = atan2(1,1) * 4;
        my $rad = $deg * ($pi/180);
        #print "deg: $deg -> rad: $rad\n";
        return $rad;
}
