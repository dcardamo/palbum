#!/usr/bin/perl
##############################################
#
#  Dan Cardamore <dan@hld.ca>
#  http://www.hld.ca/opensource
#
#  Licensed under the GPL version 2.  
#  http://www.gnu.org/licenses/gpl.html
#
##############################################

use strict;
use CGI qw(param);
use Date::Manip;

sub header()
{
	open (FILE, "</www/template/header.shtml") or print "<html><body>";
	my @file = <FILE>;
	foreach my $i (@file)
	{
		print $i;
	}
	close (FILE);
}

sub footer()
{
	open (FILE, "</www/template/footer.shtml") or print "<html><body>";
	my @file = <FILE>;
	foreach my $i (@file)
	{
		print $i;
	}
	close (FILE);
}

sub printAudio()
{
	opendir(DIR, ".");
	my @allfiles = readdir(DIR);
	my @audios;
	foreach my $file (@allfiles)
	{
		unless ( -f "$file") { next; }  # only look at files
		if ($file =~ /(wav|wave|mp3|ogg)$/i ) {
			push @audios, $file;
		}
	}

	if (not defined $audios[0]) { return; }

	print "<h2>Audio</h2><br>\n";
	print "<table border=\"1\" width=\"100%\">\n";
	print "<tr>" .
			"<td><b>Filename</b></td>" .
			"<td width=1%><b>Size&nbsp;(MB)</b></td></tr>";
	foreach my $audio (@audios)
	{
		my $filename = $audio;
		my $size = -s $filename;
		$size = $size / 1000 / 1024;  # megabytes now
		print "<tr>" .
			"<td><a href=\"$filename\">$filename</a></td>" .
			"<td>$size</td></tr>";

	}
	print "</table><br>\n";
}


sub printMovies()
{
	opendir(DIR, ".");
	my @allfiles = readdir(DIR);
	my @movies;
	foreach my $file (@allfiles)
	{
		unless ( -f "$file") { next; }  # only look at files
		if ($file =~ /(avi|mpeg|mpg|mov|asf)$/i ) {
			push @movies, $file;
		}
	}

	if (not defined $movies[0]) { return; }

	print "<h2>Movies</h2><br>\n";
	print "<table border=\"1\" width=\"100%\">\n";
	print "<tr>" .
			"<td><b>Filename</b></td>" .
			"<td width=1%><b>Size&nbsp;(MB)</b></td></tr>";
	foreach my $movie (@movies)
	{
		my $filename = $movie;
		my $size = -s $filename;
		$size = $size / 1000 / 1024;  # megabytes now
		print "<tr>" .
			"<td><a href=\"$filename\">$filename</a></td>" .
			"<td>$size</td></tr>";

	}
	print "</table><br>\n";
}



#################
#
# Check if the file photo.dat exists, if not then create it.
# If it does then generate the page from it.
#
################
sub displayIndex()
{
	# check if the file is there
	unless ( -e "photo.dat" ) {
        createPhotodat();
        return;
	}

	# open the file and get prefs and other
	open (FILE, "<photo.dat") or die print "could not open photo.dat";
	flock (FILE, 2);
	my @file = <FILE>;
	flock (FILE, 8);
	close (FILE);
	chomp @file;

    if ( not defined $file[1] ) {
        generateIndexForm();
        return;
    }

	my ($albumName, $albumDesc, $date) = split /~:~/, $file[0];
	my ($picPerPage, $bgcolor, $fontcolor) = ($file[1], $file[2], $file[3]);
	$picPerPage = 10 unless (defined $picPerPage);
	$bgcolor = "white" unless (defined $bgcolor);
	$fontcolor = "blue" unless (defined $fontcolor);
	splice @file, 0, 4;  # remove the first four lines.

	@file = sort @file;  #sort the pictures by name
	$date = ParseDate("today") unless (defined $date);
	$date = UnixDate($date, "%a %b %e, %Y");

	&header;
	print "<center><h1><u><b>$albumName</b></u></h2>\n";
	print "<b>$date</b><br>\n";
	print "<h3>$albumDesc</h3>\n";
	print "<hr>\n";

	&printMovies;  # print the movies out
	&printAudio;  # print the movies out
	print "<table border=1 cellspacing=5 width=100%>\n";
	my $picNum = 0;
	my $endedTR;
	foreach my $photo (@file)
	{
		my $mod = $picNum % 3;
		if ( $mod == 0 ) { print "<tr>\n"; $endedTR = 3; }
		my ($picName, $picDesc) = split /~:~/, $photo;
		print "<td align=center width=\"33%\">" .
			"<a href=\"index.cgi?option=displayPic\&picNum=$picNum\&width=100%\">" .
			"<img src=\"PAsmall$picName\" border=0 alt=\"$picName\"></a><br>" .
			"<font color=$fontcolor>$picDesc</font></td>\n";
		$endedTR--;
		if ( $endedTR == 0 ) { print "</tr>\n"; $endedTR = 1; }
		$picNum++;
	}
	if ( $endedTR == 2 ) { print "<td>\&nbsp;</td><td>\&nbsp;</td>\n</tr>\n"; }
	elsif ( $endedTR == 1 ) { print "<td>\&nbsp;</td>\n</tr>\n"; }
	print "</table>\n";

	print "</center>\n";
	&footer;
}


#  displays on pic and has next, prev, and back buttons
sub displayPic()
{
	my $picNum = param('picNum');
    my $height = param('height');
    my $width = param('width');
	open (FILE, "<photo.dat") or die print "Error opening photo.dat";
	flock (FILE, 2);
	my @file = <FILE>;
	flock (FILE, 8);
	close (FILE);

	chomp @file;

	my ($line, $line2);
	($line, @file) = @file;
	my ($albumName, $albumDesc, $albumDate) = split /~:~/, $line;
	($line, @file) = @file;
	my ($picsperPage) = $line;
	($line, $line2, @file) = @file;
	my ($bgcolor, $fontcolor) = ($line, $line2);
	@file = sort @file;
	my ($picName, $picDesc) = split /~:~/, $file[$picNum];

	my $prev = $picNum - 1;
	my $next = $picNum + 1;

	&header;
	print "<center>\n";
	print "<a href=index.cgi?option=displayPic\&picNum=$prev\&width=$width\&height=$height>Previous</a>  ";
	print "<a href=index.cgi>Index</a>  ";
	print "<a href=index.cgi?option=displayPic\&picNum=$next\&width=$width\&height=$height>Next</a><br><br>";

	print qx(exiftags $picName | grep Created);
    if (defined $height) {
        print "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\">";
        print "<img src=\"$picName\" border=0 alt=\"$picName\" " .
            "width=\"$width\" height=\"$height\"><br>\n";
        print "</a>\n";
    }
    elsif (defined $width) {
        print "<img src=$picName border=0 alt=$picName width=$width><br>\n";
    }
    else {
        print "<img src=$picName border=0 alt=$picName><br>\n";
    }
	print "<font color=$fontcolor>$picDesc</font><br><br>";

	print "<a href=index.cgi?option=displayPic\&picNum=$prev\&width=$width\&height=$height>Previous</a>  ";
	print "<a href=index.cgi>Index</a>  ";
	print "<a href=index.cgi?option=displayPic\&picNum=$next\&width=$width\&height=$height>Next</a><br><br>";

	print "<pre>";
	print qx(exiftags $picName);
	print "</pre>";

	print "</center>\n";
	&footer;
}

sub createPhotodat() {
    opendir (DIR, ".");
    my @allpics = readdir(DIR);
    closedir(DIR);

    chomp @allpics;
    @allpics = sort @allpics;

    my @pics;
    foreach my $pic (@allpics) {
        unless ( -f "$pic") { next; }  # only look at files
        if ( $pic eq "photo.dat" ) { next; }  # ignore photo.dat
        if ( $pic eq "index.cgi" ) { next; }  # ignore photo.dat
        if ( $pic eq "palbum.pl" ) { next; }  # ignore photo.dat
        if ( $pic =~ /PAsmall/ ) { next; }  # ignore thumbnails.
        unless ($pic =~ /(png|jpg|jpeg|gif|bmp)$/i ) { next; }

        if (-e "PAsmall$pic" ) {
            print "$pic already thumbnailed\n";
        }
        else {
            print "Thumbnailing $pic ...\n"; 
            `convert -geometry 80x80 $pic PAsmall$pic`;
        }

    }
    print "Done Creating thumbnails.  Visit this directory through the website\n";
    open FILE, ">photo.dat" or die print "There was an error creating photo.dat";
    close FILE;
    chmod 0646, "photo.dat";
}

sub generateIndex()
{
	opendir (DIR, ".");
	my @allpics = readdir(DIR);
	closedir(DIR);

	chomp @allpics;
	@allpics = sort @allpics;

	my @pics;
	foreach my $pic (@allpics)
	{
		unless ( -f "$pic") { next; }  # only look at files
		if ( $pic eq "photo.dat" ) { next; }  # ignore photo.dat
		if ( $pic eq "index.cgi" ) { next; }  # ignore photo.dat
		if ( $pic eq "palbum.pl" ) { next; }  # ignore photo.dat
		if ( $pic =~ /PAsmall/ ) { next; }  # ignore thumbnails.
        unless ($pic =~ /(png|jpg|jpeg|gif|bmp)$/i ) { next; }

		push @pics, $pic;
	}

	my $albumName = param('albumName');
	my $albumDesc = param('albumDesc');

	my $bgcolor = param('bgcolor');
	my $fontcolor = param('fontcolor');
	my $picNum = param('picNum');

	$picNum = 10 unless (defined $picNum);
	$bgcolor = "white" unless (defined $bgcolor);
	$fontcolor = "blue" unless (defined $fontcolor);

	my $date = ParseDate("today");

	open (FILE, ">photo.dat") or die print "Cannot open photo.dat for writing";
	flock (FILE, 2);

	print FILE "$albumName~:~$albumDesc~:~$date\n";
	print FILE "$picNum\n$bgcolor\n$fontcolor\n";

	foreach my $pic (@pics)
	{
		my $picDesc = param($pic);
		if (not defined $picDesc or $picDesc eq "")
		{
			$picDesc = "";
		}
		print FILE "$pic~:~$picDesc\n";
	}

	flock (FILE, 8);
	close (FILE);

	displayIndex();
}



sub generateIndexForm()
{
	unless ( -e "photo.dat" ) { die print "photo.dat exists"; }
    opendir (DIR, ".");
    my @allpics = readdir(DIR);
    closedir(DIR);

    chomp @allpics;
    @allpics = sort @allpics;

    my @pics;
    foreach my $pic (@allpics)
    {
        unless ( -f "$pic") { next; }  # only look at files
        if ( $pic eq "photo.dat" ) { next; }  # ignore photo.dat
        if ( $pic eq "index.cgi" ) { next; }  # ignore photo.dat
        if ( $pic eq "palbum.pl" ) { next; }  # ignore photo.dat
        if ( $pic =~ /PAsmall/ ) { next; }  # ignore thumbnails.
        unless ($pic =~ /(png|jpg|jpeg|gif|bmp)$/i ) { next; }

        push @pics, $pic;
    }

	print "<html><head><title>Generate Album</title></head>";
	print "<body bgcolor=white><center>\n";
	print "<font color=blue><b>Note:  The thumbnails have already been created.";
	print "  You now need to customize your photo album</b></font><br>\n";

	print "<form action=index.cgi method=post>";
	print "<input type=hidden name=option value=generateIndex>";

	# Global album properties
	print "<table width=100% border=1 cellpadding=0>\n";
	print "<tr><td colspan=2 align=center>Album Properties</td></tr>\n";
	print "<tr><td>Album Name</td><td><input type=text name=albumName></td></tr>\n";
	print "<tr><td>Album Description</td><td><input type=text " .
		"name=albumDesc></td></tr>\n";
	print "<tr><td>Background Color</td><td><input type=text name=bgcolor></td></tr>";
	print "<tr><td>Font Color</td><td><input type=text name=fontcolor></td></tr>";
	print "<tr><td>Pics per page</td><td><input type=text name=picNum></td></tr>";
	print "</table>";

	print "<hr>\n";

	# each picture properties
	print "<table border=1 width=100% cellspacing=0>\n";
	print "<tr><td><b>Thumbnail</b></td><td>Description</td></tr>\n";
	foreach my $pic (@pics)
	{
		print "<tr><td><img src=PAsmall$pic alt=$pic><br>$pic</td>";
		print "<td><input type=text name=\"$pic\"></td></tr>\n";
	}

	print "</table>\n";
	print "<input type=submit value=OK>\n";
	print "</form>\n";
	print "</center></body></html>\n";
}

print "Content-type: text/html\n\n";

my $option = param('option');
if (not defined $option)      { displayIndex(); }
elsif ($option eq "search")   { search(); }
elsif ($option eq "generateIndex")   { generateIndex(); }
elsif ($option eq "displayPic")   { displayPic(); }
else { die print "Error with option=|$option|"; }

