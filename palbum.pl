#!/usr/bin/perl


#########################
#
#  Dan Cardamore
#
#########################
#
# - If photo.dat doesn't exist then create a new one
# - each line in photo.dat contains image name ~:~ Description
# - first line conatins ALbumnName ~:~ Description
# - second line contains the number of pictures per index page
# - third line contains the background color
# - fourth color contains the font color
# - at bottom of index generated, it allows you to recreate, or search
#
##########################

use strict;
use CGI qw(param);
use Date::Manip;

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

	print "<html><head><title>$albumName - $date</title></head>\n";
	print "<body bgcolor=$bgcolor>\n";
	print "<center><h1><u><b>$albumName</b></u></h2>\n";
	print "<b>$date</b><br>\n";
	print "<h3>$albumDesc</h3>\n";
	print "<hr>\n";

	print "<table border=0 cellspacing=5 width=100%>\n";
	my $picNum = 0;
	my $endedTR;
	foreach my $photo (@file)
	{
		my $mod = $picNum % 3;
		if ( $mod == 0 ) { print "<tr>\n"; $endedTR = 3; }
		my ($picName, $picDesc) = split /~:~/, $photo;
		print "<td align=center width=\"33%\">" .
			"<a href=\"index.cgi?option=displayPic\&picNum=$picNum\">" .
			"<img src=\"PAsmall$picName\" border=0 alt=\"$picName\"></a><br>" .

            "<font size=-2>" .

            "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\&" .
            "\&width=640\&height=480\">[640x480]</a>&nbsp;" .

            "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\&" .
            "\&width=800\&height=600\">[800x600]</a>&nbsp;" .

            "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\&" .
            "\&width=1024\&height=768\">[1024x768]</a>&nbsp;" .

            "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\"" .
            ">[Actual]</a><br>" .

            "</font>" .

			"<font color=$fontcolor>$picDesc</font></td>\n";
		$endedTR--;
		if ( $endedTR == 0 ) { print "</tr>\n"; $endedTR = 1; }
		$picNum++;
	}
	if ( $endedTR == 2 ) { print "<td>\&nbsp;</td><td>\&nbsp;</td>\n</tr>\n"; }
	elsif ( $endedTR == 1 ) { print "<td>\&nbsp;</td>\n</tr>\n"; }
	print "</table>\n";

	print "</center></body></html>\n";
}


#  displays on pic and has next, prev, and back buttons
sub displayPic()
{
	my $picNum = param('picNum');
    my ($height, $width) = ( param('height'), param('width') );
    $height ||= 600;
    $width ||= 800;
	open (FILE, "<photo.dat") or die print "Error opening photo.dat";
	flock (FILE, 2);
	my @file = <FILE>;
	flock (FILE, 8);
	close (FILE);

	chomp @file;

	my ($albumName, $albumDesc) = split /~:~/, $file[0];
	my ($bgcolor, $fontcolor) = ($file[2], $file[3]);
	my ($picName, $picDesc) = split /~:~/, $file[$picNum + 4];

	my $prev = $picNum - 1;
	my $next = $picNum + 1;

	print "<html><head><title>Album: $albumName  Picture: $picName</title>";
	print "</head><body bgcolor=$bgcolor>\n";
	print "<center>\n";
	print "<a href=index.cgi?option=displayPic\&picNum=$prev\&width=$width\&height=$height>Previous</a>  ";
	print "<a href=index.cgi>Index</a>  ";
	print "<a href=index.cgi?option=displayPic\&picNum=$next\&width=$width\&height=$height>Next</a><br><br>";

    if (defined $height and defined $width) {
        print "<a href=\"index.cgi?option=displayPic\&picNum=$picNum\">";
        print "<img src=\"$picName\" border=0 alt=\"$picName\" " .
            "width=\"$width\" height=\"$height\"><br>\n";
        print "</a>\n";
    }
    else {
        print "<img src=$picName border=0 alt=$picName><br>\n";
    }
	print "<font color=$fontcolor>$picDesc</font><br><br>";

	print "<a href=index.cgi?option=displayPic\&picNum=$prev\&width=$width\&height=$height>Previous</a>  ";
	print "<a href=index.cgi>Index</a>  ";
	print "<a href=index.cgi?option=displayPic\&picNum=$next\&width=$width\&height=$height>Next</a><br><br>";
	print "</center></body></html>\n";
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
			$picDesc = "No Description";
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

