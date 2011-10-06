#/usr/bin/env perl
# Linnea.
#
use warnings;
use strict;

use Getopt::Long;

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
	"bg"               => 9
);

sub help {

	printf("Usage: %s <args> <input> <output>
  --text-bg           Text backdrop coloring (default '%s')
  --text-fg           Text forgeground color (default '%s')
  --text              Text                   (default '%s')
  --text-file         File containing text   (default '%s')
  --font-pts          Point size of font     (default '%s')
  --font              Font file              (default '%s')
  --screen            Screen number          (default %d)
  --resolution        Resolution   (default use desktop resolution)
  --text-bg-blur      bg gaussian blur intensity (default %f)
  --text-bg-contrast  bg contrast intensity      (default %f)
  --bg                bg solid color             (default none)
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
	$opts{text_bg_contrast});

}

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
	                 "bg=s"               => \$opts{bg});
help();

print "-->@ARGV <--\n";
