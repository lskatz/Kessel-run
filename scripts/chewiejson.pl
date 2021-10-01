#!/usr/bin/env perl
# Parse the json file for species listing for chewie

#system("wget -O - 'https://chewbbaca.online/api/NS/api/species/list' > chewbbaca.species.json");
# cat chewbbaca.species.json" | $0

use strict;
use warnings;
use Data::Dumper;

my $key;
my $value;

my %h;
my %species;

while(<>){
  if(/(species|name)/){
    $key = $1
  }

  if(/"value":\s+(.+)/){
    $value = $1;
    $value =~ s/^"|"$//g;
    #print "$key: $value\n";
    $h{$key}=$value;

    if($h{name} && $h{species}){
      my $id;
      if($h{species} =~ m|/(\d+)$|){
        $id = $1;
      }
      $species{$h{name}} = {
        url => $h{species},
        id  => $id,
      };

      # reset
      %h=();
    }
  }

}

# print to tsv format
my @header = qw(id url);
print join("\t", "species", @header)."\n";
while(my($name, $prop) = each(%species)){
  $name =~ s/\s+/_/g;
  print "$name";
  for my $header(@header){
    print "\t$$prop{$header}";
  }
  print "\n";
}

