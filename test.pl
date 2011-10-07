#/usr/bin/env perl
# Linnea.
#
use warnings;
use strict;

use Carp;
use Getopt::Long;

use X11::Resolution;

use Imager;
use Imager::Fill;
use Imager::Font::Wrap;

my %opts = (
	"text_bg"          => '0a0a10',
	"text_fg"          => 'ffffff',
	"text"             => '',
	"text_file"        => '',
	"font_pts"         => 14,
	"font"             => './font/Istok-Regular.ttf',
	"screen"           => 0,
	"resolution"       => '0x0',
	"text_bg_blur"     => 4.0,
	"text_bg_contrast" => 9.0,
	"bg"               => 9,
	"valign"           => 'top',    # top center bottom
	"halign"           => 'center', # left center right
	"justify"          => 'fill',   # left center right fill
);

sub help {

	printf("Usage: %s [args] <input-file> <output-file>
  --text-bg           text backdrop coloring (default '%s')
  --text-fg           text forgeground color (default '%s')
  --text              text                   (default '%s')
  --text-file         file containing text   (default '%s')
  --font-pts          point size of font     (default '%s')
  --font              font file              (default '%s')
  --screen            screen number          (default %d)
  --resolution        resolution   (default use desktop resolution)
  --text-bg-blur      bg gaussian blur intensity (default %f)
  --text-bg-contrast  bg contrast intensity      (default %f)
  --bg                bg solid color             (default none)
  --valign            vertical text alignment    (default '%s')
  --halign            horizontal text alignment  (default '%s')
  --justify           text justification method  (default '%s')
", 
	$0,
	$opts{text_bg},
	$opts{text_fg},
	$opts{text},
	$opts{text_file},
	$opts{font_pts},
	$opts{font},
	$opts{screen},
	$opts{text_bg_blur},
	$opts{text_bg_contrast},
	$opts{valign},
	$opts{halign},
	$opts{justify});

}

# Input : 6-character hex string (0a1fff) 
# Return: decimal rgb-triplet array 
sub color_parse {
	my $color = lc shift;
	if(length($color) != 6) {
		croak "Bad color '$color': " . 
		      "format is rrggbb where each 'xx'-pair is a hex-value";
	}
	my @colors;
	push @colors, hex substr($color, $_, 2) for (0, 2, 4);

	return @colors;
}

sub resolution_parse {
	my $in = lc shift;
	my @out = split /x/, $in;
	for (@out) {
		croak "Bad resolution '$in': format is WxH" if /[^\d]/;
	}
	return @out;
}

sub resolution_get {
	my $screen = shift;

	my $X = new X11::Resolution;

	if($X->{error}){
		croak "Can't instantiate X11::Resolution: " . $X->{errorString};
	}

	my ($w, $h) = $X->getResolution($screen);

	if($X->{error}){
		croak "Can't get X resolution: " . $X->{errorString};
	}

	return($w, $h);
}
##############################################################################

my $result = GetOptions ("text-bg=s"          => \$opts{text_bg},
	                 "text-fg=s"          => \$opts{text_fg},
	                 "text=s"             => \$opts{text},
	                 "text-file=s"        => \$opts{text_file},
	                 "font-pts=i"         => \$opts{text_pts},
	                 "font=s"             => \$opts{font},
	                 "screen=i"           => \$opts{screen},
	                 "resolution=s"       => \$opts{resolution},
	                 "text-bg-blur=f"     => \$opts{text_bg_blur},
	                 "text-bg-contrast=f" => \$opts{text_bg_contrast},
	                 "bg=s"               => \$opts{bg},
	                 "valign=s"           => \$opts{valign},
	                 "valign=s"           => \$opts{valign},
	                 "justify=s"          => \$opts{valign},
			 );

if(@ARGV != 2) {
	help();
	exit;
}

# Container hashes
my %src = (
	w    => 0,
	h    => 0,
	data => undef,
);
my %txt = (
	w    => 0,
	h    => 0,
	data => undef,
	color=> undef,
	font => undef,
);
my %dst = (
	file => '',
	w    => 0,
	h    => 0,
	data => undef,
);

($src{file}, $dst{file}) = @ARGV;
my @text_color_fg        = color_parse($opts{text_fg});
my @text_color_bg        = color_parse($opts{text_bg});
($dst{w}, $dst{h})       = resolution_parse($opts{resolution});

if($opts{text_file} ne '') {
	
	if($opts{text} ne '') {
		print "Overriding supplied --text with data in " .
		      "\"$opts{text_file}\"\n";
	}

	$opts{text} = '';

	open F, '<', $opts{text_file} 
		or croak "Can't open \"$opts{text_file}\": $!";

	$opts{text} .= $_ for <F>; 

	close F;

}

my $use_desktop_size = 0;

# If either width or height is zero, use desktop size.
if($dst{w} == 0 || $dst{h} == 0) {
	$use_desktop_size = 1;
	($dst{w}, $dst{h}) = resolution_get($opts{screen});
}

printf("In  : \"%s\"\n".
       "Out : \"%s\"\n". 
       "Size: %dx%d %s\n", 
       $src{file}, 
       $dst{file},
       $dst{w}, 
       $dst{h},
       $use_desktop_size ? '(desktop size)' : ''
       );


##############################################################################

# (old components - still needs work!)
# TODO:
# - clean up variable names
# - clean up error messages
# - adjust to use above opts
# .. etc

# Load source image
$src{data} = Imager->new(file     => $src{file},
			 channels => 4) or die Imager->errstr;

($src{w}, $src{h}) = ($src{data}->getwidth(), 
		      $src{data}->getheight());

# Create empty destination canvas
$dst{data} = Imager->new(xsize    => $dst{w},
			 ysize    => $dst{h},
			 channels => 4) or die Imager->errstr;

# Scale it to fit height if necessary
if($src{h} > $dst{h}) {
	my $tmp = $src{data}->scale(ypixels => $dst{h}) or die Imager->errstr;
	$src{data} = $tmp;
}

# Paste scaled image to center of canvas
# TODO take $opts{halign} into account
my $offs_x = (.5 * $dst{w}) - (.5 * $src{w});
my $offs_y = (.5 * $dst{h}) - (.5 * $src{h});

$dst{data}->paste(left => $offs_x,
		  top  => $offs_y,
		  src  => $src{data}) or die $dst{data}->errstr;

$txt{color} = Imager::Color->new(@text_color_bg);
$txt{font} = Imager::Font->new(file  => $opts{font},
			       size  => $opts{font_pts},
			       color => $txt{color}) or die Imager->errstr;

# Calculate size of annotation
# Note that we cannot know the actual width of the text;
# we can only pass our desired maximum width and this is what we get.

# Padding for blurring to dissipate without clipping.
# TODO cleanup
my $pad_x = 30;
my $pad_y = 30;

my ($l, $r); # FIXME
($l, $r, $txt{w}, $txt{h}) =
	Imager::Font::Wrap->wrap_text(string  => $opts{text},
				      font    => $opts{font},
				      image   => undef,
				      #width  => $img_src->getwidth() - $pad_x,
				      width   => $dst{w} - $pad_x,
			              justify => $opts{justify}) or die Imager->errstr;

# TODO needs to take $opts into account 
($txt{w}, $txt{h}) = ($dst{w}, 
		      $dst{w} + $pad_y);

# TODO cleanup
my $cx = .5 * $pad_x;
my $cy = .5 * $pad_y;

# Create canvas with alpha channel for transparency
$txt{data} = Imager->new(xsize    => $txt{w},
			 ysize    => $txt{h}, 
			 channels => 4) or die Imager->errstr;

# Annotate text
Imager::Font::Wrap->wrap_text(string  => $opts{text},
			      font    => $opts{font},
			      image   => $txt{data},
                              #width  => $img_src->getwidth() - $pad_x,
			      width   => $dst{w} - $pad_x,
			      justify => $opts{justify},
			      x       => $cx,
			      y       => $cy,
			      aa      => 1) or die Imager->errstr;

# Blur
$txt{data}->filter(type      => 'gaussian',
		   stddev    => $opts{text_bg_blur}) or die $txt{data}->errstr;

$txt{data}->filter(type      => 'contrast',
		   intensity => $opts{text_bg_contrast}) or die $txt{data}->errstr;

# Re-annotate 
undef $txt{color};
# Change font color to foreground
$txt{color} = Imager::Color->new(@text_color_fg);
$txt{font}->{color} = $txt{color};
Imager::Font::Wrap->wrap_text(string  => $opts{text},
			      font    => $opts{font},
			      image   => $txt{data},
                              #width  => $img_src->getwidth() - $pad_x,
			      width   => $dst{w} - $pad_x,
			      justify => $opts{justify},
			      x       => $cx,
			      y       => $cy,
			      aa      => 1) or die Imager->errstr;

# Paste (blending alpha channel via rubthrough) text on to main canvas.
# It would be nice if some alignment options were available here:
# top/bottom, for instance.
# TODO: take $opts into account
$offs_x = (.5 * $dst{w}) - (.5 * $txt{w}); # Center
# $offs_y = 0; # Top
$offs_y = $dst{h} - $txt{h}; # Bottom

$dst{data}->rubthrough(src => $txt{data},
		       tx  => $offs_x,
		       ty  => $offs_y) or die Imager->errstr;


$dst{data}->write(file => $dst{file}) or die $dst{data}->errstr;
