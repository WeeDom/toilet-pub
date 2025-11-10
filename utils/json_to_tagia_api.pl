#!/usr/bin/env perl
use strict;
use warnings;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use HTTP::Request::Common qw(POST PUT);
use File::Slurp;

# CONFIGURATION -----------------------------
my $token       = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYyNjU0ODk1LCJqdGkiOiJkZmNiZTBmOGVmNTA0NWQzOWFlNjk3MjgwNDJkNDU4YyIsInVzZXJfaWQiOjg4MzAwNH0.RbymNnGY7LiFZ6np0uyx62c2QBwwF28a4IR4fcqgcO3qIINUAE9Gh8HOUJ1NgtntZZ27oO4qWqGUaWmOodr9bvnUtjdUanAZsOnRgMHF7r4RSztlguoRa9_kURsZGAuj5lGD29BcQaDp1jQD2_O_nt_XOilvcLECCzYJtN9-VKnrsRlVGOcI6X5PAn-9RGbv_L8qxcXi7mMOnexvhDJy07Wna2vEej3qczODKXpf-78ShORGAkjr2y0jI9tg_013uo_bhQ9ikAHY68xHdoe5q-lilVY74zWl6G0ghG5NdhM0G-xNMloG59owMn3SCbt_Grng-VMjf2XhJCeVyknm_g';
my $project_id  = 1749539;                    # guard-e-loo project
my $json_file   = 'taiga_import.json';        # your exported JSON file
my $api_base    = 'https://api.taiga.io/api/v1';
# -------------------------------------------

my $ua = LWP::UserAgent->new;
$ua->default_header('Authorization' => "Bearer $token");
$ua->timeout(15);

# Confirm auth
print "🔐 Authenticating...\n";
my $me = $ua->get("$api_base/users/me");
die "❌ Auth failed: " . $me->status_line unless $me->is_success;
my $user = decode_json($me->decoded_content);
print "✅ Authenticated as $user->{full_name_display} <$user->{email}>\n";

# Confirm project exists
print "🔍 Checking project ID $project_id...\n";
my $proj = $ua->get("$api_base/projects/$project_id");
die "❌ Could not find project ID $project_id\n" unless $proj->is_success;
my $p = decode_json($proj->decoded_content);
print "✅ Found project '$p->{name}' (slug: $p->{slug})\n";

# Load import data
print "📦 Reading import file '$json_file'...\n";
my $json_text = read_file($json_file);
my $data = decode_json($json_text);

die "❌ No epics in JSON!\n" unless ref $data eq 'ARRAY' && @$data;
print "📋 Found " . scalar(@$data) . " epics to import\n\n";

# Fetch existing epics (for deduplication)
print "🔍 Fetching existing epics...\n";
my $existing_epics_res = $ua->get("$api_base/epics?project=$project_id");
my %existing_epics = ();
if ($existing_epics_res->is_success) {
    my $list = decode_json($existing_epics_res->decoded_content);
    %existing_epics = map { $_->{subject} => $_->{id} } @$list;
}
print "🧾 Found " . scalar(keys %existing_epics) . " existing epics.\n\n";

# Track mapping: Epic name → ID
my %epic_ids;

foreach my $epic (@$data) {
    my $epic_title = $epic->{title} || $epic->{name} || "Untitled Epic";
    my $epic_desc  = $epic->{description} || '';
    my $epic_id;

    # Check if this epic already exists
    if (exists $existing_epics{$epic_title}) {
        $epic_id = $existing_epics{$epic_title};
        print "♻️  Updating existing epic '$epic_title' (#$epic_id)\n";

        my $payload_epic_update = encode_json({
            subject     => $epic_title,
            description => $epic_desc,
        });

        my $update_req = HTTP::Request->new(
            'PATCH' => "$api_base/epics/$epic_id",
            [ 'Content-Type' => 'application/json' ],
            $payload_epic_update
        );
        my $update_res = $ua->request($update_req);

        if ($update_res->is_success) {
            print "  🔄 Epic '$epic_title' updated.\n";
        } else {
            warn "  ⚠️  Failed to update '$epic_title': " . $update_res->status_line . "\n";
        }
    } else {
        print "🎯 Creating new epic: $epic_title\n";
        my $payload_epic = encode_json({
            subject     => $epic_title,
            description => $epic_desc,
            project     => $project_id,
        });

        my $epic_res = $ua->request(POST("$api_base/epics",
            'Content-Type' => 'application/json',
            Content        => $payload_epic
        ));

        if ($epic_res->is_success) {
            my $epic_obj = decode_json($epic_res->decoded_content);
            $epic_id = $epic_obj->{id};
            print "  🟢 Created epic #$epic_id\n";
        } else {
            warn "  ❌ Failed to create epic '$epic_title': " . $epic_res->status_line . "\n";
            next;
        }
    }

    $epic_ids{$epic_title} = $epic_id;

    # Add any user stories linked to this epic
    if ($epic->{stories} && ref $epic->{stories} eq 'ARRAY') {
        foreach my $story (@{$epic->{stories}}) {
            my $title = $story->{title} || $story->{name} || "Untitled Story";
            my $desc  = $story->{description} || '';

            # Check if story already exists (avoid duplicates)
            my $check_url = "$api_base/userstories?project=$project_id&subject=" . $title;
            my $check_res = $ua->get($check_url);
            my $exists = ($check_res->is_success && $check_res->decoded_content =~ /$title/);

            if ($exists) {
                print "    ↩️  Skipping existing story '$title'\n";
                next;
            }

            my $payload_story = encode_json({
                subject      => $title,
                description  => $desc,
                project      => $project_id,
                epic         => $epic_id,   # 🔗 link story to epic
            });

            my $story_res = $ua->request(POST("$api_base/userstories",
                'Content-Type' => 'application/json',
                Content        => $payload_story
            ));

            if ($story_res->is_success) {
                my $story_obj = decode_json($story_res->decoded_content);
                print "    ✓ Story #$story_obj->{id}: $title\n";
            } else {
                warn "    ⚠️ Failed to create '$title': " . $story_res->status_line . "\n";
            }
        }
    }

    print "\n";
}

print "✅ Import complete. Processed " . scalar(keys %epic_ids) . " epics.\n";
exit 0;
