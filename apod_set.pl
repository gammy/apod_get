#/usr/bin/env perl
# - Crop image to desktop
# - Annotate message

# Programmatical:
# - create empty canvas of desktop size
# - load src image to new canvas
#   - crop image to height of empty canvas if it's taller than desktop
# - paste image to horizontal center of empty canvas
# - create new transparent canvas with the annotation text wrapped
#   - blur 5x or so
#   - re-annotate text wrapped over blur
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
	BLUR_DEV    => 4.5 # Higher = more
};

my @text_bg_color = (0, 0, 128, 255);
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
			      channels => 3) or die Imager->errstr;

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
my ($left, $top, $right, $bottom) =
	Imager::Font::Wrap->wrap_text(string => $text,
				      font   => $font,
				      image  => undef,
				      width  => $src->getwidth()) or die Imager->errstr;

# Add some space for blurring to dissipate without hard edges
my ($fw, $fh) = ($right + ($right / 25), 
		 $bottom + ($bottom / 25));

# Create canvas with alpha channel for transparency
my $canvas_text = Imager->new(xsize    => $fw,
			      ysize    => $fh, 
			      channels => 4) or die Imager->errstr;

# Annotate text
Imager::Font::Wrap->wrap_text(string => $text,
			      font   => $font,
			      image  => $canvas_text,
			      width  => $src->getwidth(),
			      aa     => 1) or die Imager->errstr;

# Blur
$canvas_text->filter(type => 'gaussian',
		     stddev => BLUR_DEV) or die $canvas_text->errstr;
$canvas_text->filter(type => 'contrast',
		     intensity => 3.0) or die $canvas_text->errstr;

# Re-annotate 
undef $font_color;
$font_color = Imager::Color->new(@text_fg_color);
$font->{color} = $font_color;
Imager::Font::Wrap->wrap_text(string => $text,
			      font   => $font,
			      image  => $canvas_text,
			      width  => $src->getwidth(),
			      aa     => 1) or die Imager->errstr;

$offs_x = (.5 * $w) - (.5 * $src->getwidth());
$offs_y = 0;
$canvas_base->rubthrough(src => $canvas_text,
			 tx => $offs_x,
			 ty => $offs_y) or die Imager->errstr;


##my $c = Imager::Color->new(0, 0, 0, 0);
##$canvas_text->fill($c);
#print "dims: $left, $top, $right, $bottom\n";

# Write output
$canvas_base->write(file => "out.png") or die $canvas_base->errstr;
