#!/usr/bin/env perl
# Get full-size APOD as well as description.
# Should be run at least once per day.
#
# It skips the image download if the file already
# exists locally.
#
# by gammy.

use warnings;
use strict;

use constant DST_PATH  => $ENV{HOME} . '/.APOD';

use APOD;

if(! -e DST_PATH) {
	mkdir DST_PATH, 0744 or die $!;
}

my $apod = new APOD;

$apod->peek() or die "$!";

# There should always be a description
die "It doesn't seem like we could parse the page" if ! $apod->description;

# No image? - just die.
die "No image found (perhaps it's a video today).\n" if ! $apod->url;

# Set destination path
$apod->destination(DST_PATH);

my $img_path = $apod->destination . '/' . $apod->filename;
my $dsc_path = "$img_path.txt";

die "Already got \"$img_path\".\n" if -e $img_path;

$apod->save_image();
print "Saved \"$img_path\"\n";

$apod->save_description();
print "Saved \"$dsc_path\"\n";
