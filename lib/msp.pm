package lib::msp ;

use strict;
use warnings ;
use Exporter ;
use Carp ;

use Data::Dumper ;
use List::MoreUtils qw(uniq);

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( get_mzs get_intensities get_masses_from_string get_intensities_from_string keep_only_max_masses keep_only_max_intensities encode_spectrum_for_query sorting_descending_intensities round_num apply_relative_intensity remove_redundants);
our %EXPORT_TAGS = ( ALL => [qw( get_mzs get_intensities get_masses_from_string get_intensities_from_string keep_only_max_masses keep_only_max_intensities encode_spectrum_for_query sorting_descending_intensities round_num apply_relative_intensity remove_redundants)] );

=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

=head1 METHODS

Methods are :

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    bless($self) ;
    return $self ;
}
### END of SUB



=head2 METHOD get_mzs

	## Description : parse msp file and get mzs
	## Input : $msp_file, $mzRes, $maxIon
	## Output : \@total_spectra_mzs 
	## Usage : my ( $mzs ) = get_mzs( $msp_file , $mzRes, $maxIon) ;
	## Structure of res: [ $arr_ref1 , $arr_ref2 ... $arr_refN ]
=cut
## START of SUB
sub get_mzs {
	## Retrieve Values
    my $self = shift ;
    my ( $msp_file, $mzRes ) = @_ ;
  
  	my @ions = () ;
  	my @temp_mzs = () ;
  	my @uniq_masses ;
  	my @mzs = ();
  	my @total_spectra_mzs = ();
  	my $mz ;
  	my $i = 0 ;
  	  	
    open (MSP , "<" , $msp_file) or die $! ;
    
	{
		local $/ = 'Name' ;
	    my @infos = () ;
	    # One line is : "Name -> Name" englobing a whole spectrum with all infos
	    while(my $line = <MSP>) {
	    	
	    	chomp $line;
	    	@infos = split (/\n/ , $line) ;
	    	# Loop over all lines of a spectrum
	    	for (my $i=0 ; $i<@infos ; $i++) {
	    		# Detect spectrum lines only
		    	if ($infos[$i] =~ /(\d+\.?\d*)\s+(\d+\.?\d*)\s*;\s*/) {
		    		
		    		@ions = split ( /;/ , $infos[$i] ) ;
		    		# Retrieve mzs according to maxIons value
		    		foreach my $ion (@ions) {
		    			
		    			if ($ion =~ /^\s*(\d+\.?\d*)\s+(\d+\.?\d*)$/) {
		    				
		    				$mz = $1 ;
		    				# Truncate/round mzs depending on $mzRes wanted
		    				if ($mzRes == 0) {
		    					my $mz_rounded = sprintf("%.".$mzRes."f", $mz) ;
		    					push (@temp_mzs , $mz_rounded) ;
		    				}
		    				# Check that $mzRes is not greater than the number of digits after comma
		    				elsif ($mzRes > 0) {
		    					if ($mz !~ /^\d+\.\d+$/) { croak "*********\n\nYou are trying to specify $mzRes significant decimals, but one or more masses in the input file are unitary masses.\nYou should try again with mzRes = 0\n\n\n"; }
		    					elsif($mzRes > length(( $mz =~ /.+\.(.*)/)[0] )) {
		    						$mz = sprintf("%.".$mzRes."f" , $mz) ;
		    					}
		    					my $mz_rounded = _round_num($mz,$mzRes) ;
		    					push (@temp_mzs , $$mz_rounded) ;
		    				}
		    			}
		    		}
		    	}
	    	}
	    	if($line ne '') {
		    	@{ $total_spectra_mzs[$i] } = @temp_mzs ;
			    $i++ ;
			    @temp_mzs = () ;
	    	}  	
	    }
    }
    #print Dumper \@total_spectra_mzs ;
    close (MSP) ;
    return(\@total_spectra_mzs) ;
}
## END of SUB




=head2 METHOD get_intensities

	## Description : parse msp file and get intensities
	## Input : $msp_file, $maxIons
	## Output : \@total_spectra_intensities 
	## Usage : my ( $intensities ) = get_mzs( $msp_file, $maxIons ) ;
	## Structure of res: [ $arr_ref1 , $arr_ref2 ... $arr_refN ]
=cut
## START of SUB
sub get_intensities {
	## Retrieve Values
    my $self = shift ;
    my ( $msp_file ) = @_ ;
  
  	my @ions = () ;
  	my @temp_intensities = () ;
  	my @intensities = () ;
  	my @total_spectra_intensities = (); 
  	my $i = 0 ;
  	
    open (MSP , "<" , $msp_file) or die $! ;
    
    {
		local $/ = 'Name' ;
	    my @infos = () ;
	    # Extract spectrum
	    while(my $line = <MSP>) {
	    	chomp $line;
	    	@infos = split (/\n/ , $line) ;
	    	#Detect spectrum
	    	for (my $i=0 ; $i<@infos ; $i++) {
		    	if ($infos[$i] =~ /(\d+\.?\d*)\s+(\d+\.?\d*)\s*;\s*?/) {
		    		@ions = split ( /;/ , $infos[$i] ) ;
		    		# Retrieve intensities
		    		foreach my $ion (@ions) {
		    			if ($ion =~ /^\s*(\d+\.?\d*)\s+(\d+\.?\d*)$/) {
    						my $intensity = $2 ;
    						push ( @temp_intensities , $intensity ) ;
		    			}
		    		}
		    	}
	    	}
	    	if($line ne '') {
		    	@{ $total_spectra_intensities[$i] } = @temp_intensities ;
			    $i++ ;
			    @temp_intensities = () ;	  
	    	}  	
	    }
    }
    close (MSP) ;
    return(\@total_spectra_intensities) ;
}
## END of SUB


=head2 METHOD get_masses_from_string

	## Description : parse a spectrum string and get mzs and intensities
	## Input : $spectrum_string, $mzRes
	## Output : \@spectrum_intensities_mzs 
	## Usage : my ( $spectrum_mzs ) = get_masses_from_string( $spectrum_string , $mzRes ) ;
=cut
## START of SUB
sub get_masses_from_string {
	## Retrieve Values
    my $self = shift ;
    my ( $spectrum_string, $mzRes ) = @_ ;
    
    my @intensities = () ;
    my @mzs = () ;
        
    if (defined $spectrum_string) {
    	
    	if ($spectrum_string ne '') {
    		
    		if ($spectrum_string =~ /\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s*/ ) {
    		
	    		my @val = split (/\s+/ , $spectrum_string) ;
	    		for (my $i=0 ; $i<@val ; $i++) {
	    			if ($i%2 == 0) {
	    				my $mz = $val[$i] ;
	    				# Truncate/round mzs depending on $mzRes wanted
	    				if ($mzRes == 0) {
	    					$mz = int($mz) ;
	    					push ( @mzs , $val[$i] ) ;
	    				}
	    				# Check that $mzRes is not greater than the number of digits after comma
	    				elsif ($mzRes > 0) {
	    					if($mzRes > length(( $mz =~ /.+\.(.*)/)[0] )) {
	    						$mz = sprintf("%.".$mzRes."f" , $mz) ;
	    					}
	    					my $mz_rounded = _round_num($mz,$mzRes) ;
	    					push ( @mzs , $$mz_rounded ) ;
	    				}
	    			}
	    		}
	    		return (\@mzs) ;
    		}
    		else { croak "Wrong format of the spectrum. See help\n" }
    	}
    	else { croak "Spectrum is empty, the service will stop\n" } ;
    }
    else { croak "Spectrum is not defined, service will stop\n" } ;
}
## END of SUB



=head2 METHOD get_intensities_from_string

	## Description : parse a spectrum string and get intensities
	## Input : $spectrum_string
	## Output : \@spectrum_intensities 
	## Usage : my ( $spectrum_intensities ) = get_intensities_from_string( $spectrum_string ) ;
=cut
## START of SUB
sub get_intensities_from_string {
	## Retrieve Values
    my $self = shift ;
    my ( $spectrum_string ) = @_ ;
    
    my @intensities = () ;
    my @mzs = () ;
        
    if (defined $spectrum_string) {
    	
    	if ($spectrum_string ne '') {
    		
    		if ($spectrum_string =~ /\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s*/ ) {
    		
	    		my @val = split (/\s+/ , $spectrum_string) ;
	    		for (my $i=0 ; $i<@val ; $i++) {
	    			if ($i%2 != 0) {
	    				my $int = $val[$i] ;
	    				push ( @intensities , $int ) ; 
	    			}
	    		}
	    		return (\@intensities) ;
    		}
    		else { croak "Wrong format of the spectrum. See help\n" }
    	}
    	else { croak "Spectrum is empty, the service will stop\n" } ;
    }
    else { croak "Spectrum is not defined, service will stop\n" } ;
}
## END of SUB





=head2 METHOD sorting_descending_intensities

	## Description : sort mzs and intensities arrays by descending intensity values
	## Input : $ref_mzs_res, $ref_ints_res
	## Output : \@mzs_res, \@ints_res 
	## Usage : my ( \@mzs_res, \@ints_res ) = sorting_descending_intensities( $ref_mzs_res, $ref_ints_res ) ;
=cut
## START of SUB
sub sorting_descending_intensities {
	## Retrieve Values
    my $self = shift ;
    my ( $ref_mzs_res, $ref_ints_res ) = @_ ;
    
    my @mzs_res = () ;
    my @ints_res = () ;
    
    if ( defined $ref_mzs_res && defined $ref_ints_res ) {
    	if ( (scalar @$ref_mzs_res) != 0 && (scalar @$ref_ints_res) != 0 ) {
		    
		    @mzs_res = @$ref_mzs_res ;
			@ints_res = @$ref_ints_res ;
			
			# Case when we have only one array of masses (input is a string of masses and not a file)
		    if ( ref(@$ref_ints_res[0]) ne "ARRAY") {
		    
		    	my @sorted_indices = sort { $ints_res[$b] <=> $ints_res[$a] } 0..$#ints_res;
				@$_ = @{$_}[@sorted_indices] for \(@mzs_res, @ints_res);
				
		    }
			else {
				## Sorting ions by decreasing intensity values
				for (my $i=0 ; $i<@ints_res ; $i++) {
					my @sorted_indices = sort { @{$ints_res[$i]}[$b] <=> @{$ints_res[$i]}[$a] } 0..$#{$ints_res[$i]};
					@$_ = @{$_}[@sorted_indices] for \(@{$ints_res[$i]},@{$mzs_res[$i]});
				}
			}
    	} 
    	else { carp "Cannot sort intensities, mzs or intensities are empty" ; return (\@mzs_res, \@ints_res) ; } 
    } 
    else { carp "Cannot sort intensities, mzs or intensities are undef" ; return (\@mzs_res, \@ints_res) ; }
    
	return (\@mzs_res, \@ints_res) ;
}
## END of SUB




=head2 METHOD keep_only_max_masses

	## Description : keep only $maxIons masses 
	## Input : $mzs_res_sorted, $maxIons
	## Output : \@mzs
	## Usage : my ( $mzs ) = keep_only_max_masses( $mzs_res_sorted, $ints_res_sorted, $maxIons ) ;
=cut
## START of SUB
sub keep_only_max_masses {
	## Retrieve Values
    my $self = shift ;
    my ( $ref_mzs_res, $maxIons ) = @_ ;
    
    my @mzs = () ;
    my @tot_mzs = () ;
    
    if ( ref(@$ref_mzs_res[0]) ne "ARRAY") {
    	my $i = 0 ;
    	while (scalar @tot_mzs < $maxIons && $i < @$ref_mzs_res){
	    	push (@tot_mzs , $$ref_mzs_res[$i++]) ;
    	}
    }
    else {
	    for (my $i=0 ; $i<@$ref_mzs_res ; $i++) {
		  	my $j = 0 ;
		    while (scalar @mzs < $maxIons && $j < @$ref_mzs_res[$i]){
		    	push (@mzs , $ref_mzs_res->[$i][$j++]) ;
	    	}
	    	push (@tot_mzs , \@mzs) ;
	    }
    }
	return (\@tot_mzs) ;
}
## END of SUB




=head2 METHOD keep_only_max_intensities

	## Description : keep only $maxIons intensities 
	## Input : $ints_res_sorted, $maxIons
	## Output : \@ints
	## Usage : my ( $ints ) = keep_only_max_intensities( $ints_res_sorted, $maxIons ) ;
=cut
## START of SUB
sub keep_only_max_intensities {
	## Retrieve Values
    my $self = shift ;
    my ( $ref_ints_res, $maxIons ) = @_ ;
    
    my @ints = () ;
    my @tot_ints = () ;
	if ( ref(@$ref_ints_res[0]) ne "ARRAY") {
    	my $i = 0 ;
    	while (scalar @tot_ints < $maxIons && $i < @$ref_ints_res){
	    	push (@tot_ints , $$ref_ints_res[$i++]) ;
    	}
    }
    else {
    	for (my $i=0 ; $i<@$ref_ints_res ; $i++) {
	    	my $j = 0 ;
	    	while (scalar @ints < $maxIons && $j < @$ref_ints_res[$i]){
	    		push (@ints , $ref_ints_res->[$i][$j++]) ;
	    	}
	    	push (@tot_ints , \@ints) ;
    	}
    }    
	return (\@tot_ints) ;
}
## END of SUB





=head2 METHOD encode_spectrum_for_query

	## Description : get mzs and intensities values and generate the spectra strings formatted for the WS query (html) 
	## Input : $mzs, $intensities
	## Output : \@encoded_spectra
	## Usage : my ( $encoded_spectra ) = get_spectra( $mzs, $intensities ) ;
	
=cut
## START of SUB
sub encode_spectrum_for_query {
	## Retrieve Values
    my $self = shift ;
    my ( $mzs, $intensities ) = @_ ;
    
    my @encoded_spectra = () ;
    my $spectrum = "" ;
    my $k = 0 ;
    
    #print Dumper $mzs ;
    
    if ( defined $mzs && defined $intensities ) {
    	if ( @$mzs && @$intensities ) {
    		
    		# Case when we have only one array of masses (input is a string of masses and not a file)
		    if ( ref(@$mzs[0]) ne "ARRAY") {
    			for (my $i=0 ; $i< @$mzs ; $i++) {
    				$spectrum = $spectrum . @$mzs[$i] . " " . @$intensities[$i] . " ";
    			}
			    push ( @encoded_spectra , $spectrum ) ;
		    }
		    else {
			    for (my $i=0 ; $i< @$mzs ; $i++) {
			    	
			    	for ( my $j=0 ; $j< @{ @$mzs[$i] } ; $j++ ) {
			    		
			    		$spectrum = $spectrum . $$mzs[$i][$j] . " " . $$intensities[$i][$j] . " ";
			    	}
			    	$encoded_spectra[$k] = $spectrum ;
			    	$k++ ;
			    	$spectrum = '' ;
			    }
		    }
    	}
    	else { carp "Cannot encode spectrum, mzs and intensities arrays are empty" ; return \@encoded_spectra ; }
    }
    else { carp "Cannot encode spectrum, mzs and intensities are undef" ; return \@encoded_spectra ; }
    return \@encoded_spectra ;
}
## END of SUB


=head2 METHOD round_num

	## Description : round a number by the sended decimal
	## Input : $number, $decimal
	## Output : $round_num
	## Usage : my ( $round_num ) = round_num( $number, $decimal ) ;
	
=cut
## START of SUB 
sub _round_num {
    ## Retrieve Values
    my ( $number, $decimal ) = @_ ;
    my $round_num = 0 ;
    
	if ( ( defined $decimal ) and ( $decimal > 0 ) and ( defined $number ) and ( $number > 0 ) ) {
        $round_num = sprintf("%.".$decimal."f", $number);	## a rounding is used : 5.3 -> 5 and 5.5 -> 6
	}
	else {
		croak "Can't round any number : missing value or decimal\n" ;
	}
    
    return(\$round_num) ;
}
## END of SUB



=head2 METHOD apply_relative_intensity

	## Description : transform absolute intensities into relative intensities
	## Input : $intensities
	## Output : \@intensities
	## Usage : my ( $intensities ) = apply_relative_intensity( $intensities ) ;
	
=cut
## START of SUB 
sub apply_relative_intensity {
	## Retrieve Values
	my $self = shift ;
    my ($intensities) = @_ ;
    
    my @intensities = @$intensities ;
    my @relative_intensities ;
    
    foreach my $ints (@intensities) {
    		my @relative_ints = map { ($_ * 100)/@$ints[0] } @$ints ;
    		push (@relative_intensities , \@relative_ints) ;
    }
    return \@relative_intensities ;
}
## END of SUB



=head2 METHOD remove_redundants

	## Description : removes ions with redundant masses
	## Input : $masses $intensities
	## Output : \@intensities
	## Usage : my ( $uniq_masses, $uniq_intensities ) = remove_redundants( $masses, $intensities ) ;
	
=cut
## START of SUB 
sub remove_redundants {
	## Retrieve Values
	my $self = shift ;
    my ($masses, $intensities) = @_ ;
    
    my %uniq = () ;
    my @uniq_intensities = () ;
    
    ## Create hash with key = mass and value = intensity
    for (my $i=0 ; $i<@$masses ; $i++) {
    	$uniq{ @$masses[$i] } = @$intensities[$i] ;
    }
    
    ## Remove redundant masses
    my @uniq_masses = uniq(@$masses) ;
    
    ## Keep intensities corresponding to uniq masses
	foreach my $mass (@uniq_masses) {
	    push (@uniq_intensities , $uniq{ $mass }) ;
	}
	
	return (\@uniq_masses , \@uniq_intensities) ;
	
}  
## END of SUB


#********************************************************************************************************
#	FONCTION DU SEUIL POUR LE BRUIT, A DECOMMENTER SI FINALEMENT CE N'EST PAS GERE DANS LA BRIQUE MetaMS
#********************************************************************************************************


=head2 METHOD keep_ions_above_threshold

	## Description : keep only ions which intensities are above the threshold
	## Input : $mzs_res_sorted, $ints_res_sorted, $noiseThreshold
	## Output : $mzs_res_noise_threshold, $ints_res_noise_threshold
	## Usage : my ( $mzs_res_noise_threshold, $ints_res_noise_threshold ) = keep_ions_above_threshold( $mzs_res_sorted, $ints_res_sorted, $noiseThreshold ) ;
	
=cut
## START of SUB 
#sub keep_ions_above_threshold {
#	## Retrieve Values
#	my $self = shift ;
#    my ($mzs_res_sorted, $ints_res_sorted, $noiseThreshold) = @_ ;
#    
#    my (@mzs_res_noise_threshold, @ints_res_noise_threshold) = ( (),() ) ;
#    my (@mzs_res_noise_threshold_temp, @ints_res_noise_threshold_temp) = ( (),() ) ;
#    my $i = 0 ;
#    my $j = 0 ;
#    # Case when we have only one array of masses (input is a string of masses and not a file)
#    if ( ref(@$mzs_res_sorted[0]) ne "ARRAY") {
#    	
#		while( @$ints_res_sorted[$i] > $noiseThreshold && $i < scalar @$mzs_res_sorted) {
#    	
#	    	push ( @mzs_res_noise_threshold , @$mzs_res_sorted[$i] ) ;
#	    	push ( @ints_res_noise_threshold , @$ints_res_sorted[$i] ) ;
#	    	$i++ ;
#	    }
#	}
#    else {
#    	while( $i < @$ints_res_sorted ) {
#    		
#    		while( $$ints_res_sorted[$i][$j] > $noiseThreshold && $j < scalar @$ints_res_sorted[$i]) {
#    			
#    			push ( @mzs_res_noise_threshold_temp , $$mzs_res_sorted[$i][$j] ) ;
#		    	push ( @ints_res_noise_threshold_temp , $$ints_res_sorted[$i][$j] ) ;
#		    	$j++ ;
#    		}		
#    		push ( @mzs_res_noise_threshold , \@mzs_res_noise_threshold_temp ) ;
#		    push ( @ints_res_noise_threshold , \@ints_res_noise_threshold_temp ) ;
#    		$i++ ;
#    	}
#	}
#	
#	return (\@mzs_res_noise_threshold, \@ints_res_noise_threshold) ;
#}  
## END of SUB


#********************************************************************************************************
#********************************************************************************************************
#********************************************************************************************************


1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc csv.pm

=head1 Exports

=over 4

=item :ALL is get_spectra

=back

=head1 AUTHOR

Gabriel Cretin E<lt>gabriel.cretin@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 03 / 06 / 2016

version 2 : 24 / 06 / 2016

=cut