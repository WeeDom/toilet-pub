#!/usr/bin/env perl
use strict;
use warnings;
use JSON;

# Parse TODO.md and export to Taiga-compatible JSON format

my $todo_file = '../TODO.md';
open my $fh, '<', $todo_file or die "Cannot open $todo_file: $!";

my @epics;
my $current_epic;
my $epic_counter = 1;
my $story_counter = 1;

while (my $line = <$fh>) {
    chomp $line;

    # Match Epic headers: ### Epic N: Title
    if ($line =~ /^### Epic \d+: (.+)$/) {
        my $epic_title = $1;
        $epic_title =~ s/[^\w\s-]//g;  # Remove emojis

        $current_epic = {
            ref => $epic_counter++,
            subject => $epic_title,
            description => "",
            status => "New",
            user_stories => []
        };
        push @epics, $current_epic;
    }
    # Match Goal
    elsif ($line =~ /^\*\*Goal\*\*: (.+)$/) {
        $current_epic->{description} = $1 if $current_epic;
    }
    # Match Status
    elsif ($line =~ /^\*\*Status\*\*: (.+)$/) {
        my $status_text = $1;
        if ($status_text =~ /COMPLETE/) {
            $current_epic->{status} = "Done";
        } elsif ($status_text =~ /READY TO START|PARTIALLY COMPLETE/) {
            $current_epic->{status} = "In progress";
        } else {
            $current_epic->{status} = "New";
        }
    }
    # Match Stories: - **Story X.X**: Status - Description
    elsif ($line =~ /^- \*\*Story .+?\*\*: (.+?) - (.+)$/) {
        my ($status_marker, $description) = ($1, $2);

        my $story_status = "New";
        if ($status_marker =~ /✅|COMPLETE/) {
            $story_status = "Done";
        } elsif ($status_marker =~ /HIGH PRIORITY/) {
            $story_status = "Ready";
        }

        my $story = {
            ref => $story_counter++,
            subject => $description,
            description => "",
            status => $story_status,
            points => undef
        };

        push @{$current_epic->{user_stories}}, $story if $current_epic;
    }
    # Match sub-items (task details)
    elsif ($line =~ /^  - (.+)$/ && $current_epic && @{$current_epic->{user_stories}}) {
        my $last_story = $current_epic->{user_stories}[-1];
        $last_story->{description} .= "- $1\n";
    }
}

close $fh;

# Create Taiga import structure
my $taiga_export = {
    epics => \@epics,
    project => {
        name => "Guard-e-Loo",
        description => "Privacy-aware public toilet security system"
    }
};

# Output JSON
my $json = JSON->new->pretty->encode($taiga_export);
print $json;

# Also save to file
my $output_file = 'taiga_import.json';
open my $out, '>', $output_file or die "Cannot write to $output_file: $!";
print $out $json;
close $out;

print STDERR "\n✅ Exported to $output_file\n";
print STDERR "📋 Found " . scalar(@epics) . " epics\n";

my $total_stories = 0;
$total_stories += scalar(@{$_->{user_stories}}) for @epics;
print STDERR "📝 Found $total_stories user stories\n";
