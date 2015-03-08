#!/usr/bin/perl
# This script can be used to check the Wordpress version of several sites against the current stable Wordpress version. 
# It uses meta tag "generator" to determine the version of each WP site. The resutls are sent via email. 
#
# May be useful when you're responsible for several WP sites and do not feel like activating Automatic Background Updates 
# (you may need to check plug-ins compatibility first in some cases). 
#
#       .--' |
#      /___^ |     .--.
#          ) |    /    \
#         /  |  /`      '.
#        |   '-'    /     \
#        \         |      |\
#         \    /   \      /\|
#          \  /'----`\   /
#          |||       \\ |
#          ((|        ((|
#          |||        |||
#  perl   //_(       //_(   script :)

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Email::MIME;

my $wp_url = 'https://wordpress.org/latest.tar.gz';
my $message = '';

# get information from $wp_url using HEAD method
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
my $response = $ua->head($wp_url);


if ($response->is_success) {
	if ($response->header('content-disposition') =~ m/wordpress-([0-9\.]+)\.tar\.gz/) {
		my $wp_version = $1;
		my $wp_site_content;
		my $wp_update_url;
		my $wp_site_version;
		
		foreach my $url (
			'http://www.example.com/blog/',
			# 'more here', 
		) {
			#print "\n$url\n";
			my $wp_site = LWP::UserAgent->new;
			$wp_site->timeout(10);
			$wp_site->env_proxy;
			$wp_site_content = $wp_site->get($url);
			if ($wp_site_content->is_success) {
				if ($wp_site_content->decoded_content =~ m/<meta\s+name=\"generator\"\s+content=\"WordPress\s+([0-9\.]+)"/) {
					$wp_site_version = $1;
					if ($wp_site_version ne $wp_version) {
						$wp_update_url = $url;
						$wp_update_url =~ s/\/$//; #remove the trailing /
						$message .= "- $url is version $wp_site_version (update here: $wp_update_url/wp-admin/update-core.php ) \n";
					}
					else { $message .= "- $url is up-to-date\n"; }
				}
				else {
					$message .= "- unable to determine WP version of $url - hidden generator tag?\n";
				}
			}
			else {
				$message .= "- unable to determine read $url\n";
			}
			undef $wp_site;
			undef $wp_site_content;
			undef $wp_site_version;
			sleep 5;
		}
		
		if ($message ne '') {
			
			$message = "The following sites have been checked against the current stable version of Wordpress: \n\n\n" . $message;
			
			my $email_message = Email::MIME->create(
			  header_str => [
			    From    => 'from@example.com',
			    To      => 'to@example.com',
			    Subject => 'Wordpress sites report',
			  ],
			  attributes => {
			    encoding => 'quoted-printable',
			    charset  => 'ISO-8859-1',
			  },
			  body_str => $message,
			); 
			use Email::Sender::Simple qw(sendmail);
			sendmail($email_message);
		}
	}
	else {
		die 'Unable to determine current stable Wordpress version';
	}
	
}
else {
    die $response->status_line;
}