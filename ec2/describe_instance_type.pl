#!/usr/bin/perl
# AWS CLI doesn't offer a way to describe instance types.
# This script scrapes that information from AWS website by parsing HTML tables, 
# then it creates yaml files that are going to be used by project: https://github.com/RedHatQE/dva

use locale;
use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Data::Dumper;

binmode STDOUT, ":utf8";

my $html_file = 'ec2_types.html';
my @variants_table;
my $variants;
my @variant;
my $memory_zeroes;
my $number_of_columns;
my $ec2_url = 'https://aws.amazon.com/ec2/instance-types/';

system ('wget', $ec2_url, "--output-document=$html_file", '--user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"') and print "error - cannot load \n";

	
unless (-e $html_file) {
	print "File Doesn't Exist!";
	exit();
} 

my $tree = HTML::TreeBuilder::XPath->new;

$tree->parse_file($html_file);
	
@variants_table = $tree->findnodes('//div[@class="aws-table"]/table/tbody/tr');

for $variants ( @variants_table ) {
		
		@variant = $variants->findvalues('./td');

		$number_of_columns = $#variant;
		if ($number_of_columns!=11 && $number_of_columns!=12) {
			print "wrong table, skipping...\n";
			next;
		}

		# skip the first table row
		if ($variant[0] eq 'Instance Type') { next; } 

		if ($variant[2] =~ m/0\./) { $memory_zeroes = '00000'; } 
		else { $memory_zeroes = '000000'; }
		
		$variant[2] =~ s/0\.//;
		
		$variant[0] =~ s/\s+//;
		
		print $variant[0];
		print ": ";
		print $variant[2] . " GB";
		print "\n";
		
		open FILE, ">", "x86_64_hvm_" . $variant[0] . ".yaml" or die $!;
		
		print FILE "- {arch: 'x86_64', cpu: '".$variant[1]."', memory: '".$variant[2]. $memory_zeroes ."', cloudhwname: ".$variant[0].", virtualization: 'hvm'}\n";
		  
		close FILE;
}
$tree->delete;