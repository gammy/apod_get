#!/usr/bin/env perl
# by gammy
use warnings;
use strict;

=head1 NAME

 APOD - Astronomy Picture Of the Day module.

=head1 DESCRIPTION

 A simple helper to fetch the image and description of NASAs 
 Astronomy Picture Of The Day.
 
=head1 SYNOPSIS

 use APOD;
 my $apod = new APOD;
  
 # Peek at the APOD website to fill in the image url, description, etc.
 # Always call this method first.
 $apod->peek();

 $apod->destination("/tmp/");

 if(-e $apod->destination . '/' . $apod->filename) {
	 die "We already have the APOD!\n";
 }
 
 $apod->save_image();
 $apod->save_description();
 
=head1 Getters

 $url_to_image      = $apod->url;
 $image_data        = $apod->image; # requires ->get_image() or ->save_image()
 $original_filename = $apod->filename;
 $description       = $apod->description;
 $destination_dir   = $apod->description;
 
=head1 Setters

 $new_dest = $apod->destination("/new/destination/");
 
=cut

package APOD;

use base qw/HTML::Parser/;

use constant BASE_URL     => 'http://apod.nasa.gov';

use Carp;
use LWP::Simple;
use HTML::Parser;

my $text_buf;
my $path_found = 0;

# Getters
sub url         { return $_[0]->{url}; }
sub image       { return $_[0]->{image}; }
sub filename    { return $_[0]->{filename}; }
sub description { return $_[0]->{description}; }

# Getter/setter
sub destination { 
	my $self = shift;
	if(@_) {
		$self->{destination} = shift;
	} else {
		if(! $self->{destination}) {
			$self->{destination} = './';
		}
	}

	return $self->{destination};
};

# Get the APOD webpage and find image url & description. 
# Always call this first.
sub peek {
	my $self = shift;
	my $html = get(BASE_URL) or croak "Failed to get \"" . BASE_URL . "\"";
	$self->parse($html);
}

sub get_image {
	my $self = shift;
	my $url = $self->{url};
	$self->{image} = get($url) or croak "Can't get \"$url\"!";
}

sub save_image {
	my $self = shift;
	my $dst = $self->destination . '/' . $self->{filename};

	croak "Call peek() first!" if ! $self->{description};

	$self->get_image();
	
	# user-defined argument overrides the /entire/ path including 'destination'
	if(@_) { 
		$dst = shift;
	}

	open F, '>', $dst or croak "Can't open \"$dst\": $!";
	print F $self->{image};
	close F;
}

sub save_description {
	my $self = shift;
	my $dst = $self->destination . '/' . $self->{filename} . '.txt';

	croak "Call peek() first!" if ! $self->{description};
	
	# user-defined argument overrides the /entire/ path  including 'destination'
	if(@_) { 
		$dst = shift;
	}

	open F, '>', $dst or croak "Can't open \"$dst\": $!";
	print F $self->{description};
	close F;
}

# Overrides empty HTML::Parser sub
sub start { 
	my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

	if($tagname eq 'p') {
		if($text_buf =~m/Explanation:/s) {
			$text_buf =~s/\n+/\n/g;
			$text_buf =~s/\n/ /g;
			$text_buf =~s/ +/ /g;
			$text_buf =~s/^ //g;
			$text_buf =~s/ $//g;
			$self->{description} = $text_buf;
		
		}
		$text_buf = '';
	}elsif($tagname eq 'a') {
		if($attr->{href}=~m#(image/.*)#s) {
			$self->{url}        = BASE_URL . '/' . $1 if ! $path_found;
			$self->{filename}   = substr($self->{url}, 
			                             rindex($self->{url}, '/') + 1);
			$path_found = 1;
		}
	}
}

# Overrides empty HTML::Parser sub
sub text {
	my ($self, $text) = @_;
	$text_buf .= $text;

}

1;
