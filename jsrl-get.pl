#!/usr/bin/perl -w
use strict;
use warnings;

use Getopt::Std;
use LWP;
use File::Path qw(make_path);
use IO::File;

my $opts = {};
getopts('sv', $opts);
if (!$opts->{s} && !$opts->{v}) {
  print "Downloading both songs and videos. You can choose by passing -s or -v as flags.\n";
  $opts->{s} = $opts->{v} = 1;
}

my $songs_dir = "songs/";
my $jsrl_url = "https://jetsetradio.live/audioplayer/audio/";

my $lwp = LWP::UserAgent->new;
$lwp->show_progress(1);

if ($opts->{s}) {
  for my $station ("", "poisonjam/", "noisetanks/", "loveshockers/") {
    my $list = $lwp->get($jsrl_url.$station."~list.js");
    die "Error getting the list for '$jsrl_url$station~list.js'" if $list->is_error;

    for my $line (split /^/, $list->content) {
      if ($line =~ /"([^"]*)"/) {
        my $title = $1;
        my $filename = $title.".mp3";
        my $url = $jsrl_url.$station.$filename;
        my $stn = $station eq "" ? "jsrl/" : $station;
        my $path = $songs_dir.$stn;

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
}

my $videos_dir = "videos/";
my $jsrl_tv_url = "https://jetsetradio.live/tv/videoplayer/videos/";

# List taken on 2016-09-03 from the web inspector console at https://jetsetradio.live/tv/ by running
# for (i in filesListArray) { console.log(filesListArray[i]); }
my @tv_videos = <<END =~ m/^(.*)\n/mg;
VISUAL - Giant Bubble Reflections
BUMP - Terminal
XSPORT - Richie Eisler in CANADA USD
BUMP - Collecteur 3
SHORT FILM - Allegoria Sacra
VISUAL - CHROMO
VISUAL - Walking City
VISUAL - Desert Villa Visualization
XSPORT - Angry Girl Sofia Bogdanova
JAPAN - New National Stadium
BUMP - In Space
XSPORT - Fly like a Butterfly
BUMP - Skyline
MUSIC VIDEO - SOFLES - LIMITLESS
MUSIC VIDEO - Martin Solveig ft Dragonette - Big In Japan
GRAFFITI - Foster The People - Coming of Age Mural Time-Lapse
COMEDY - Golden Pizza
VISUAL - ASCIDIA remix
GRAFFITI - URI Tags its Gallery
BUMP - Bathrooms
JSR CONTENT - Real Life Jet Set Radio
VISUAL - Arc of Wonder
BUMP - Tunnel Vision
JSR CONTENT - JET SET RADIO LIVE - Welcome to JetSetRadio LIVE
BUMP - z00sebump
JAPAN - Travel Look
BUMP - Collecteur 2
JSR CONTENT - PROJECT BEAT - INSIDE LOOK
RETRO COMMERCIAL - Seaman 5
VISUAL - Oil
TRAVEL - New York City
BUMP - You da man bomb
BUMP - Recipe
VISUAL - Barcelona KALEIDOLAPSE remix
GRAFFITI - TO THE FUTURE mural in Toronto by yougottalove
BUMP - Broadcast
JSR CONTENT - PROJECT BEAT - Multiplayer Test
MUSIC VIDEO - Madeon - Pop Culture (Dance Video)
BUMP - Millenials
RETRO COMMERCIAL - Seaman 2
JSR CONTENT - Did You Know Gaming
GRAFFITI - Bombing Action
VISUAL - Parametric Expression
JSR CONTENT - PROJECT BEAT - Progress Report
GRAFFITI - Zase v Dekor Turtle Race - Graffiti Time Lapse
JSR CONTENT - Beat's sexy dance Jet Set Radio
XSPORT - Lazerwheelz - RED FIRE - Freeskate with Andy Egido
VISUAL - Ghost Cell
JSR CONTENT - PROJECT BEAT - alexacat
XSPORT - RollerBlading Tricks
JSR CONTENT - PROJECT BEAT - Teaser
VISUAL - Deep Dream Nosedive
BUMP - Rainbump
VISUAL - Sync by Max Hattler
BUMP - Carefree
BUMP - Collecteur 1
SHORT FILM - Trimalchio
JAPAN - Tokyo Train Ride
RETRO COMMERCIAL - Seaman 4
XSPORT - Joey McGarry - suckitsmallwheels
MUSIC VIDEO - Parov Stelar - Demon Dance
VISUAL - BELLS MUSIC VIDEO Remix
VISUAL - OutRun in HD - Sega Arcade Version
VISUAL - City Lights Across The Delta
XSPORT - Freeskate slides shuffles derrapes
RETRO COMMERCIAL - Chu-Chu Rocket
JSR CONTENT - Jet Set Radio - Kill It With Fire
RETRO COMMERCIAL - Seaman 6
RETRO COMMERCIAL - Seaman 3
BUMP - Water
JSR CONTENT - JET SET LUCIO
GRAFFITI - Vexta - St Kilda Police Station
VISUAL - Retrowave
XSPORT - The Best Rollerblading (2015)
XSPORT - Freeskate in Shanghai 80mm
XSPORT - Tips for beginners
JAPAN - Tokyo Dense Fog
VISUAL - NATS Europe
JSR CONTENT - JET SET RADIO LIVE - CURIO 1
GRAFFITI - VIRUS 2016
GRAFFITI - Rake Abandoned House
BUMP - Two Routers
GRAFFITI - Granny VS Buggsy Ft Sokem One
XSPORT - South Korean Longboarder Ko Hyojoo Rolls Through Seoul
VISUAL - Hyper Drive YURIKAMOME
GRAFFITI - TV DEPOT
JSR CONTENT - Jet Set Radio HD Official Trailer
VISUAL - BIRDMASK Visuals
GRAFFITI - ERIC HAZE x STUSSY x DEFRAG
VISUAL - Shawn Wasabi Marble Soda
XSPORT - Best of Freestyle Skating Singapore
JSR CONTENT - Funky Dealer - KineticTypography
COMEDY - I made 500 dollars
XSPORT - Jacob Sutton’s LED Surfer
JSR CONTENT - PROJECT BEAT - How to Get to the Top of Rokkaku Dai
JSR CONTENT - Jet Set Radio Documentary - The Rude Awakening
COMEDY - Kazuma Kiryu answers a telephone
BUMP - Collecteur 4
BUMP - Concept of JSRL
RETRO COMMERCIAL - Seaman 1
VISUAL - Conductor MTA
VISUAL - Visual Division
JAPAN - Shibuya Tokyo
VISUAL - Chameleon
BUMP - Classical Music
BUMP - Id Buy That For A Dollar
VISUAL - Mirror City Timelapse
GRAFFITI - EL MAC RETNA
BUMP - Record
VISUAL - It's paper
VISUAL - Bach The Well Tempered Clavier for Sinfini Music
GRAFFITI - LINES 01 - OMSK167
JSR CONTENT - GUM IS BAE alexacatplays part1
RETRO COMMERCIAL - Jet Set Radio
XSPORT - Sofia August
GRAFFITI - A Writer Knows
END

if ($opts->{v}) {
  for my $videofn (@tv_videos) {
    my $filename = $videofn.".mp4";
    my $url = $jsrl_tv_url.$filename;

    print "Downloading $url to $videos_dir$filename...\n";
    my $video = $lwp->get($url);
    die "Error getting '$videofn' ($url)" if $video->is_error;

    make_path($videos_dir);
    my $fh = IO::File->new($videos_dir.$filename, "w");
    if (defined $fh) {
      binmode $fh;
      print $fh $video->content;
      undef $fh;
    } else {
      print "Error creating $videos_dir$filename!\n";
    }
  }
}
