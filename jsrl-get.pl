#!/usr/bin/perl -w
use strict;
use warnings;

use LWP;
use File::Path qw(make_path);
use IO::File;

my $out_dir = "songs/";
my $jsrl_url = "https://jetsetradio.live/audioplayer/audio/";

my $lwp = LWP::UserAgent->new;
$lwp->show_progress(1);

for my $station ("", "poisonjam/", "noisetanks/", "loveshockers/") {
  my $list = $lwp->get($jsrl_url.$station."~list.js");
  die "Error getting the list for '$jsrl_url$station~list.js'" if $list->is_error;

  for my $line (split /^/, $list->content) {
    if ($line =~ /"([^"]*)"/) {
      my $title = $1;
      my $filename = $title.".mp3";
      my $url = $jsrl_url.$station.$filename;
      my $stn = $station eq "" ? "jsrl/" : $station;
      my $path = $out_dir.$stn;

      print "Downloading $url to $path...\n";
      my $song = $lwp->get($url);
      die "Error getting '$title' ($url)" if $song->is_error;

      make_path($path);
      my $fh = IO::File->new($path.$filename, "w");
      if (defined $fh) {
        binmode $fh;
        print $fh $song->content;
        undef $fh;
      } else {
        print "Error creating $path$filename!\n";
      }
    }
  }
}
