#/usr/bin/env perl
# - Crop image to desktop
# - Annotate message

# Programmatical:
# - create empty canvas of desktop size
# - load src image to new canvas
#   - crop image to height of empty canvas if it's taller than desktop
# - paste image to horizontal center of empty canvas
# - create transparent canvas with the annotation text wrapped
#   - apply heavy gaussian blur to "smear" the text out for
#     use as a 'shadow' for the text
#   - increase contrast (does it saturate?)
#   - re-annotate text
# - paste annotation canvas to top horizontal center of canvas
# - store result

use warnings;
use strict;

use Data::Dumper;
use X11::Resolution;
use Imager;
use Imager::Fill;
use Imager::Font::Wrap;
#use Image::Magick;

use constant { 
	SCREEN_NUM  => 0,
	FONT_NAME   => '',
	FONT_PTS    => 14,
	FONT_FILE   => './font/Istok-Regular.ttf',
	BLUR_DEV    => 4.0, # Higher = more smeared background blur
	INTENSITY   => 9.0  # Higher = more contrast on background blur
};

#my @text_bg_color = (64, 64, 128, 255);
my @text_bg_color = (10, 10, 16, 255);
#my @text_fg_color = (255, 255, 255, 255);
my @text_fg_color = (255, 255, 255, 255);

if(@ARGV != 2) {
	die "Usage: $0 <filename> <text>\n";
}

my ($filename, $text) = @ARGV;

if(! -e $filename) {
	die "Can't find \"$filename\"";
}

## Get resolution
my $X = new X11::Resolution;
if($X->{error}){
	die "Can't instantiate X11::Resolution: " . $X->{errorString};
}

my ($w, $h) = $X->getResolution(SCREEN_NUM);

if($X->{error}){
	die "Can't get X resolution: " . $X->{errorString};
}

printf("Resolution of screen %d: %dx%d\n", SCREEN_NUM, $w, $h);

# Create empty canvas
my $canvas_base = Imager->new(xsize    => $w,
			      ysize    => $h,
			      channels => 4) or die Imager->errstr;

# Load source image
my $src = Imager->new(file     => $filename,
		      channels => 4) or die Imager->errstr;

# Scale it to fit height if necessary
if($src->getheight() > $h) {
	my $tmp = $src->scale(ypixels => $h) or die Imager->errstr;
	$src = $tmp;
}

# Paste scaled image to center of canvas
my $offs_x = (.5 * $w) - (.5 * $src->getwidth());
my $offs_y = (.5 * $h) - (.5 * $src->getheight());
$canvas_base->paste(left => $offs_x,
		    top  => $offs_y,
		    src  => $src) or die $canvas_base->errstr;

my $font_color = Imager::Color->new(@text_bg_color);
my $font = Imager::Font->new(file  => FONT_FILE,
			     size  => FONT_PTS,
			     color => $font_color) or die Imager->errstr;

# Calculate size of annotation
# Note that we cannot know the actual width of the text;
# we can only pass our desired maximum width and this is what we get.
my ($left, $top, $right, $bottom) =
	Imager::Font::Wrap->wrap_text(string  => $text,
				      font    => $font,
				      image   => undef,
				      width   => $src->getwidth(),
			              justify => 'left') or die Imager->errstr;

# Add some space for blurring to dissipate without noticable clipping.
my $pad_x = 20;
my $pad_y = 20;
my ($fw, $fh) = ($right + $pad_x, 
		 $bottom + $pad_y);
my $cx = .5 * $pad_x;
my $cy = .5 * $pad_x;

# Create canvas with alpha channel for transparency
my $canvas_text = Imager->new(xsize    => $fw,
			      ysize    => $fh, 
			      channels => 4) or die Imager->errstr;

# Annotate text
Imager::Font::Wrap->wrap_text(string => $text,
			      font   => $font,
			      image  => $canvas_text,
			      width  => $src->getwidth(),
			      x      => $cx,
			      y      => $cy,
			      aa     => 1) or die Imager->errstr;

# Blur
$canvas_text->filter(type => 'gaussian',
		     stddev => BLUR_DEV) or die $canvas_text->errstr;
$canvas_text->filter(type => 'contrast',
		     intensity => INTENSITY) or die $canvas_text->errstr;

# Re-annotate 
undef $font_color;
$font_color = Imager::Color->new(@text_fg_color);
$font->{color} = $font_color;
Imager::Font::Wrap->wrap_text(string => $text,
			      font   => $font,
			      image  => $canvas_text,
			      width  => $src->getwidth(),
			      x      => $cx,
			      y      => $cy,
			      aa     => 1) or die Imager->errstr;

# Paste (blending alpha channel via rubthrough) text on to main canvas.
# It would be nice if some alignment options were available here:
# top/bottom, for instance.
$offs_x = (.5 * $w) - (.5 * $fw); # Center
# $offs_y = 0; # Top
$offs_y = $h - $fh; # Bottom
$canvas_base->rubthrough(src => $canvas_text,
			 tx => $offs_x,
			 ty => $offs_y) or die Imager->errstr;


# Write output
$canvas_base->write(file => "out.png") or die $canvas_base->errstr;
