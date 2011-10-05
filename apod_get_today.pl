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

use LWP::Simple;
use HTML::Parser;

use constant DST_PATH  => $ENV{HOME} . '/.APOD';
use constant BASE_URL  => 'http://apod.nasa.gov';

#############################################################################
package APOD;
use base qw/HTML::Parser/;

our ($url, $description);

my $text_buf;
my $path_found = 0;

sub start { 
	my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

	if($tagname eq 'p') {
		if($text_buf =~m/Explanation:/s) {
			$text_buf =~s/ +/ /g;
			$text_buf =~s/\n+//g;
			$text_buf =~s/^ //g;
			$text_buf =~s/ $//g;
			$description = $text_buf;
		
		}
		$text_buf = '';
	}elsif($tagname eq 'a') {
		if($attr->{href}=~m#(image/.*)#s) {
			$url = $1 if ! $path_found;
			$path_found = 1;
		}
	}
}

sub text {
	my ($self, $text) = @_;
	$text_buf .= $text;

}

#############################################################################
package main;

if(! -e DST_PATH) {
	mkdir DST_PATH, 0744 or die $!;
}

my $page = get(BASE_URL) or die "Failed to get \"" . BASE_URL . "\"";
#open TEST, '<', "/home/gammy/ap111004.html";
#my $page;
#$page .= $_ for <TEST>;
#close TEST;

my $apod = new APOD;
$apod->parse($page);

# There should always be a description
if(! $APOD::description) {
	die "It doesn't seem like we could parse the page";
} 

# No image? No description name - just die.
if(! $APOD::url) {
	die "No image found (perhaps it's a video today).\n";
}

my $img_url = BASE_URL . "/$APOD::url";
my $img_filename = DST_PATH . '/' . substr($APOD::url, 
	                                   rindex($APOD::url, '/') + 1);
my $dsc_filename = "$img_filename.txt";

if(-e $img_filename) {
	die "Already got \"$img_filename\".\n";
}

my $img_data = get($img_url) or die "Failed to get \"$img_url\"";

open F, '>', $img_filename or die "$img_filename: $!";
print F $img_data;
close F;
print "Saved \"$img_filename\"\n";

open F, '>', $dsc_filename or die "$dsc_filename: $!";
print F $APOD::description;
close F;
print "Saved \"$dsc_filename\"\n";
