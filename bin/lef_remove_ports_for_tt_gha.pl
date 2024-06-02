#!/usr/bin/perl
#
#	bin/lef_remove_ports_for_tt_gha.pl lef/myfile.lef > lef/myfile.lef.n && mv -fv lef/myfile.lef lef/myfile.lef.o && mv -iv lef/myfile.lef.n lef/myfile.lef
#	diff -u lef/myfile.lef.o lef/myfile.lef
#
use strict;

sub is_removed {
    $_[0] =~ /^oa_.*$/;
}

my $emit = 1;
my $pin;
while(<>) {
    if(!$emit && /^\s*END\s+(\S+)\s*$/) {
        if($pin eq $1) {
            $emit = 1;
            next; # slip this line too
        }
    }
    if(/^\s*PIN\s+(\S+)\s*$/) {
        if(&is_removed($1)) {
            $pin = $1;
            $emit = 0;
            print STDERR "REMOVING: $^:$. $pin\n";
        }
    }
    print $_ if($emit);
}
