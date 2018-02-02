#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Getopt::Std;
use LWP;
use File::Path qw(make_path);
use IO::File;
use XML::Parser;

# Initialization and option parsing
my $opts = {};
getopts('svi', $opts);
if (!$opts->{s} && !$opts->{v}) {
  print "Downloading both songs and videos. You can choose by passing -s or -v respectively as flags.\n";
  $opts->{s} = $opts->{v} = 1;
}
if (!$opts->{i}) {
  print "If you want to print info when an existing song is skipped, use -i.\n";
}
my $lwp = LWP::UserAgent->new;
$lwp->show_progress(1);

# Songs configuration
my $songs_dir = "songs/";
my $jsrl_url = "https://jetsetradio.live/audioplayer/audio/";
my @stations = ("", "poisonjam/", "noisetanks/", "loveshockers/", "rapid99/", "immortals/", "doomriders/", "goldenrhinos/", "christmas/", "bumps/");

if ($opts->{s}) {
  for my $station (@stations) {
    my $list = $lwp->get($jsrl_url.$station."~list.js");
    die "Error getting the list for '$jsrl_url$station~list.js'" if $list->is_error;

    for my $line (split /^/, $list->content) {
      if ($line =~ /"([^"]*)"/) {
        my $filename = $1.".mp3";
        my $url = $jsrl_url.$station.$filename;
        my $stn = $station eq "" ? "jsrl/" : $station;
        my $path = $songs_dir.$stn;

        download($url, $path, $filename);
      }
    }
  }
}

# Videos configuration
my $videos_dir = "videos/";
my $jsrl_tv_url = "https://jetsetradio.live/tv/APP/videoplayer/videos/";
my $jsrl_tv_list_url = "https://jetsetradio.live/tv/APP/preloader/retrieveTotalFilesAndFilesList.php";

if ($opts->{v}) {
  my $list = $lwp->get($jsrl_tv_list_url);
  die "Error getting the video list '$jsrl_tv_list_url'" if $list->is_error;

  my $xml = XML::Parser->new(Style => 'Tree');
  my $response = $xml->parse($list->content);

  my $size = $response->[1][4][2]; # <totalFiles>
  my $tv_videos_str = $response->[1][8][2]; # <fileListArray>
  $tv_videos_str =~ s/^\[|\]$//g;

  my @tv_videos = split(/,/, $tv_videos_str);
  @tv_videos = map { $_ =~ s/^"|"$//g; $_ } @tv_videos;

  # Parse \uXXXX escape sequences
  @tv_videos = map { $_ =~ s/\\u(\d{4})/chr(hex($1))/ge; $_ } @tv_videos;

  die "Mismatch between fileListArray size and totalFiles!" if scalar @tv_videos != $size;

  for my $videofn (@tv_videos) {
    my $filename = $videofn.".mp4";
    my $url = $jsrl_tv_url.$filename;

    download($url, $videos_dir, $filename);
  }
}

# Downloads a file, skipping it if it already exists
sub download {
  my ($url, $dir, $filename) = @_;
  if (-e $dir.$filename) {
    print "Skipping $filename (already downloaded)...\n" if $opts->{i};
    return;
  }

  my $req = $lwp->get($url);
  die "Error getting '$url'" if $req->is_error and $req->code != 404;
  return if $req->code == 404;

  make_path($dir);
  my $fh = IO::File->new($dir.$filename, "w");
  if (defined $fh) {
    binmode $fh;
    print $fh $req->content;
    undef $fh;
  } else {
    print "Error creating $dir$filename!\n";
  }
}
