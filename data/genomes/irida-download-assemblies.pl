#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Tiny;
use Getopt::Long qw(GetOptions);
use Parse::CPAN::Meta;
use Term::ANSIColor;
use Data::Dumper;

my $usage = <<"HELP";
Usage:
	$0 [--help] --username USERNAME --api-url URL --client-id CLIENT_ID --client-secret CLIENT_SECRET [--password password] [--output DIR]

	--help 		Print this message
	--username 	Your IRIDA/NGS Archive username
	--password 	Your IRIDA/NGS Archive password (if you do not provide a value, you will be prompted to enter one)
	--api-url	The IRIDA API that you want to connect to.
	--client-id	The Client ID you were issued.
	--client-secret	The Client secret you were issued.
	--project	The project to download assemblies from.
HELP

my $api;
my $oauth_token_url;
my $username;
my $password;
my $client_id;
my $client_secret;
my $output_dir = "output";
my $project;
my $help;

GetOptions(
	'help' => \$help,
	'api-url=s' => \$api,
	'username=s' => \$username,
	'password=s' => \$password,
	'project=i' => \$project,
	'client-id=s' => \$client_id,
	'client-secret=s' => \$client_secret,
	'output=s' => \$output_dir );

if ($help or not ($username and $client_id and $client_secret and $api and $project)) {
	print color('bold red');
	print "Username, api-url, client-id, client-secret, and project are required options.\n" unless $help;
	print color('reset');
	print $usage;
	exit(not $help);
}

if (not $password) {
	# allow user to type in password here:
	print 'Password: ';
	system('stty -echo');
	$password = <STDIN>;
	chomp $password;
	system('stty echo');
	print "\n";
}

mkdir $output_dir if (not -e $output_dir);

$oauth_token_url = "$api/oauth/token";

my $response = HTTP::Tiny->new->post_form($oauth_token_url, {
			client_id => $client_id,
			client_secret => $client_secret,
			grant_type => "password",
			username => $username,
			password => $password });

#print Dumper($response),"\n";

# To future explorers:
#    I'm abusing this because it comes with core and I don't want to explain to
#    people how to install perl modules if they don't have them. (JSON is not 
#    in core, but Parse::CPAN::Meta is).
my $oauth_info = Parse::CPAN::Meta->load_json_string($response->{'content'});
my $oauth_access_token = $oauth_info->{'access_token'};

unless ($oauth_access_token) {
	print color('bold red');
	print "Could not log in to IRIDA, please check your username and password.\n";
	print color('reset');
	print $usage;
	exit(1);
}

# For communicating with REST API
my $client = HTTP::Tiny->new(default_headers => {
					'Authorization' => "Bearer $oauth_access_token"
				},
				agent => "IRIDA Assembly Download");

# For downloading a file
my $file_client = HTTP::Tiny->new(default_headers => {
					'Authorization' => "Bearer $oauth_access_token",
					'Accept' => 'text/plain'
				},
				agent => "IRIDA Assembly Download");

my $project_samples_link = "$api/projects/$project/samples";

my $samples = Parse::CPAN::Meta->load_json_string(
	$client->get($project_samples_link)->{'content'})->{'resource'}->{'resources'};

foreach my $sample (@$samples) {
	my ($seq_files_link) = grep { $_->{'rel'} eq 'sample/sequenceFiles/pairs' } @{$sample->{'links'}};

	#print Dumper($sample),"\n";

	my $seq_files = Parse::CPAN::Meta->load_json_string(
		$client->get($seq_files_link->{'href'})->{'content'})->{'resource'}->{'resources'};

	foreach my $seq_file (@{$seq_files}) {
		my ($assemblies_link) = grep { $_->{'rel'} eq 'analysis/assembly' } @{$seq_file->{'links'}};

		#print Dumper($seq_file),"\n";

		if (not defined $assemblies_link) {
			warn "No assembly for sequence file pair [$seq_file->{'label'}] in sample [$sample->{'sampleName'}]";
		} else {
			my $assembly_submission = Parse::CPAN::Meta->load_json_string(
				$client->get($assemblies_link->{'href'})->{'content'})->{'resource'};

			#print Dumper($assembly_submission),"\n";

			if ($assembly_submission->{'analysisState'} ne 'COMPLETED') {
				warn "No assembly for sequence file pair [$seq_file->{'label'}] in sample [$sample->{'sampleName'}]. Assembly [$assembly_submission->{'identifier'}] not in state COMPLETED";
			} else {
				my ($assembly_analysis_link) = grep { $_->{'rel'} eq 'analysis' } @{$assembly_submission->{'links'}};

				my $assembly_analysis = Parse::CPAN::Meta->load_json_string(
					$client->get($assembly_analysis_link->{'href'})->{'content'})->{'resource'};

				#print Dumper($assembly_analysis),"\n";

				# Defines the particular file to download
				# See https://irida.corefacility.ca/documentation/developer/rest/#assembly-and-annotation-links for more options
				my $download_rel = 'outputFile/contigs-with-repeats';
				my ($assembly_output_link) = grep { $_->{'rel'} eq $download_rel } @{$assembly_analysis->{'links'}};

				my $file_contents = $file_client->get($assembly_output_link->{'href'});
				#print Dumper($file_contents),"\n";

				# A unique identifier to add to file name in case a sample has multiple assemblies associated with it
				my $assembly_submission_identifier = $assembly_submission->{'identifier'};

				my $file_name = "$sample->{'sampleName'}_irida-submission-$assembly_submission_identifier.fasta";
				my $file_path = "$output_dir/$file_name";

				print "Saving file $file_path from $assembly_output_link->{'href'}\n";
				open (my $out_fh, ">$file_path");
				print $out_fh $file_contents->{'content'};
				close($out_fh);
			}
		}
	}
}	