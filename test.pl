#/usr/bin/env perl
# Linnea.
#
use warnings;
use strict;

use Getopt::Long;

use constant { 
	DEFAULT_TEXT_BG => '0a0a10',
	DEFAULT_TEXT_FG => 'ffffff',
	# Text      (no default)
	# Text-file (no default)
	DEFAULT_FONT_PTS=> 14,
	DEFAULT_FONT    => './font/Istok-Regular.ttf',
	DEFAULT_SCREEN  => 0,
	# Resolution (no default)
	DEFAULT_BLUR    => 4.0,  # Higher = more smeared background blur
	DEFAULT_CONTRAST=> 9.0,  # Higher = more contrast on background blur
};

$result = GetOptions ("text-bg=s"          => \$opts{text_bg},
		      "text-fg=s"          => \$opts{text_fg},
		      "text=s"             => \$opts{text},
		      "text-file=s"        => \$opts{text_file},
		      "font-pts=i"         => \$opts{text_pts},
		      "font=s"             => \$opts{font},
		      "screen=i"           => \$opts{screen},
		      "resolution=s"       => \$opts{resolution}, #override desktop
		      "text-bg-blur=f"     => \$opts{text_bg_blur},
		      "text-bg-contrast=f" => \$opts{text_bg_contrast},
		      "bg=s"               => \$opts{bg});

sub help {
}
