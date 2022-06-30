#!/usr/bin/perl

use Mojo::Util qw(getopt dumper);
use Mojo::JSON qw(decode_json);

getopt
    'h|help' => \my $help,
    'm|module=s' => \my $module,
    'f|from=s' => \my $host,
    'b|build=i' => \my $last_build,
    'p|parent=s' => \my $parent,
    'j|job_group=s' => \my $job_group_ids;

help() if ($help);
our $command = 'openqa-cli api -p';
sub help {
    my $help_message = <<EOF;
Usage: openqa-search-job-by-module -m module_name -f osd/o3 -j 268,269
Options:
  -f, --form         Search job_modules from where
  -h, --help         Show this summary of available options
  -m, --module       module name
  -p, --parent       parent job group's id or name
  -j, --job_groups   job groups' id or name, separated with comma

EOF
    
    print $help_message . "\n";
    exit 0;
}

sub getParentGroups {
    my $json_parents_groups = qx{$command --$host parent_groups/ 2>&1};
    if ($? ne 0) {
        print "Fail to get parent job groups information: $json_parents_groups \n";
        exit 1;
    }
    my $all_parents_groups = decode_json($json_parents_groups);
    my $parents_groups;
    foreach (@$all_parents_groups) {
        next if ($_->{name} =~ /Development/);
        unless ($parent) {
            $parents_groups->{$_->{id}} = $_->{name};
            next;
        }
        if ($_->{id} eq $parent || $_->{name} eq $parent) {
            $parents_groups->{$_->{id}} = $_->{name};
        }
    }
    return $parents_groups;

}
  
sub getJobGroups {
    my $param = shift;
    my $json_groups = qx{$command --$host job_groups/ 2>&1};
    if ($? ne 0) {
        print "Fail to get job groups information: $json_groups";
        exit 2;
    }
    my $parent_id = $param->{parent_id};
    my %expected_groups = map { $_=>1 } @{$param->{job_group_ids}};
    my $all_groups = decode_json($json_groups);
    my @job_groups;
    foreach my $g (@$all_groups) {
        if ($parent_id ne '') {
            push @job_groups, {id => $g->{id}, name => $g->{name}, parent_group_name => $parent_group_name} if ($g->{parent_id} eq $parent_id);
        }
        else {
            if ($expected_groups{$g->{id}}) {
                push @job_groups, {id => $g->{id}, name => $g->{name}, parent_group_name => $parent_group_name};     
            }
        }
    }
    die "No job group found! \n" if (scalar(@job_groups) <= 0);
    return \@job_groups;
}

sub getJobs {
    my $job_groups = shift;
    my $build_limit = $last_build ? $last_build : 2;
    my @array_results;
    foreach my $group (@$job_groups) {
        my $json_builds = qx{curl -s $url/group_overview/$group->{id}.json?limit_builds=$build_limit};
        if ($? ne 0) {
            print "Fail to get job group's build information \n";
            exit 3;
        }
        my $build_details = decode_json($json_builds);
        my $build_results = $build_details->{build_results};
        foreach my $build (@$build_results) {
            my $num = $build->{build};
            my $json_jobs = qx{$command --$host jobs/overview groupid=$group->{id} modules=$module build=$num 2>&1};
            if ($? ne 0) {
                print "Fail to get jobs information: $json_jobs \n";
                exit 4;
            }
            my $jobs = decode_json($json_jobs);
            next if (scalar(@$jobs) <= 0);
            $group->{result}->{$num} = $jobs;
        }
        push @array_results, $group;
    }
    return @array_results;
}

our $url = $host eq 'osd' ? 'https://openqa.suse.de' : 'https://openqa.opensuse.org';
my $parent_group_id = $parent ? $parent : ($host eq 'osd' ? 7 : '' );
my @job_group_ids = $job_group_ids ? split(/,/, $job_group_ids) : ($host eq 'o3' ? (1, 3) : ());
my $groups = getJobGroups({parent_id => $parent_group_id, job_group_ids => \@job_group_ids});
my @result = getJobs($groups);

foreach my $group (@result) {
    print "Job Group:\n";
    print "ID: $group->{id}\n";
    print "Name: $group->{name} \n";
    print "Parent group name: $group->{parent_group_name} \n";
    foreach my $build (keys %{$group->{result}}) {
        my $jobs = $group->{result}->{$build};
        print "\tBuild $build:\n";
        print "\t\t Name: $_->{name} \n\t\t Link: $url/tests/$_->{id}\n" for(@$jobs);
    }
}