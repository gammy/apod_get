#!/usr/bin/env perl
# 
# - Grab APOD feed (usually contains a weeks worth of items)
# - For each item in the feed,
#   - Grab the APOD page and parse it for the full-size image URL
#   - If we haven't already done so, download the image.
#
# Run this weekly (or twice a week.. or hey why not once per day :p) 
#
# by gammy.

use warnings;
use strict;

use LWP::Simple;
use XML::RSS::Parser;

use constant BASE_URL  => 'http://apod.nasa.gov';
use constant FEED_URL  => BASE_URL . "/apod.rss";
use constant DST_PATH  => $ENV{HOME} . '/.APOD';

if(! -e DST_PATH) {
	mkdir DST_PATH, 0744 or die $!;
}

print "Storing images in \"" . DST_PATH . "\".\n";

my $xml = get(FEED_URL) or die 'Failed to get "' . FEED_URL . '"';

my $parser = new XML::RSS::Parser;
my $feed = $parser->parse_string($xml);

print $feed->item_count . " items.\n";

$| = 1;
for my $item ($feed->query('//item')) {

	my $title = $item->query('title')->text_content;
	my $link = $item->query('link')->text_content;

	print "Get \"$title\"..";
	
	my $tmp = get($link) or die "failed to get \"$link\"";

	# We won't use the 'img src' since this is usually cropped.
	# In case they show a video or something, I assume they don't
	# have them in the "image/"-directory.
	if($tmp=~m#a href="(image/.+?)"#si) {

		my $img_url = BASE_URL . "/$1";
		my $filename = substr($1, rindex($1, '/') + 1);

		my $full_path = DST_PATH . "/$filename";

		if(-e $full_path) {
			print "already got it.\n";
			next;
		}

		my $img_data = get($img_url) or die "failed to get \"$img_url\"";

		open F, '>', DST_PATH . "/$filename" or die $!;
		print F $img_data;
		close F;
		
		print "ok.\n";
	} else {
		print "contains no image.\n"
	}

}

$| = 0;
