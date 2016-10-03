#!/usr/bin/perl
#usage
#dbash.pl [-v] -c command1 -c command2... -c commandN -t script1 -t script2 ... -t scriptN
#scripts are just text files with one command per space
#multiple commands/scripts are executed one at a time
#when both scripts and commands are present commands are executed first followed by scripts  

use strict; use warnings;
use Text::ParseWords;
use File::Basename;
use Getopt::Long;
my (@cmds,$verbose,@textFiles,$local);

GetOptions("command=s" => \@cmds,      #one line pipes - use docker:: to identify docker containers - files must be full path
           "textFile=s" =>\@textFiles, #text files with multiple commands
           "local" => \$local,         #the script is run locally instead of inside a container - this affects which files need to be mounted
           "verbose" =>\$verbose);
foreach my $textFile(@textFiles){
	if(!$local){$textFile="/local/".$textFile}
	@cmds=(@cmds,split(/\r?\n/,`cat $textFile`)); 
}		           		           
foreach my $cmd (@cmds){
	unless($cmd && $cmd =~ /\s/){next;}
 if($verbose){print STDERR "Input command is:\n$cmd\n";}
 my(@tokens,@ops,@stdinTokens,@stdinOps);
 #first replace all stdin redirects with stdin::
 #we use findTokenOps instead of a simpler approach to handle case where < is inside a quote
 findTokensOps($cmd,"<+",\@stdinTokens,\@stdinOps);
 my $stdinSeen;
 foreach my $stdinOp (@stdinOps){
  if($stdinOp =~ s/\</stdin\:\:/){
			$stdinSeen++;
		}	
	}
	if($stdinSeen){
  #build new cmd
  $cmd="";
  foreach my $i (0..$#stdinTokens){
			#remove blank space at beginning of token for stdin
			if($i != 0 &&  $stdinOps[$i-1] && $stdinOps[$i-1] =~/stdin\:\:/){
				$stdinTokens[$i] =~ s/^\s+//;
			}	
			$cmd.=$stdinTokens[$i];
			if($i <= $#stdinOps){
				$cmd.=$stdinOps[$i];
			}	
		}			
	}
 #now find the tokens wrt to pipes and redirects
 findTokensOps($cmd,"[\|\>\&]+",\@tokens,\@ops);
 my @newTokens;
 foreach my $i (0..$#tokens){
		my $token=$tokens[$i];
		#tokens with docker:: are to be run with docker
  if(!$local || $token=~ /docker\:\:/){
			my $dockerBase;
			if($token =~ /docker\:\:/){
				$dockerBase="sudo docker run --rm -i ";
 	 	$token=~ s/docker\:\://;
			}
 		my (@execs,$dirSeen);
 	 my @parts=quotewords(' ',1,$token);
 	 my @bareParts=quotewords(' ',0,$token);
	  push(@execs,$parts[0]);
 	 foreach my $j (1..$#parts){
				my $part=$parts[$j];
				my $barePart=$bareParts[$j];
				if($part && $barePart){
				#check if stdin::
				 if($part =~ s/stdin\:\://){
				 	if(!$local && $barePart !~ /stdin\:\:\/dev\//){
				 		$part="< /local/".$part;
	 	  	 $dirSeen++;
				 	}
				 	else{
				 		$part="< " .$part;
				 	}	
				 }	
			 	elsif($barePart =~ /^\S?\// && $barePart !~ /^\S?\/dev/) {
	 	  	$part="/local/".$part;
	 	  	$dirSeen++;
			  }	
	 	  push(@execs,$part);
				}
	  }
	  if($dockerBase){
	   if($dirSeen){ $dockerBase = $dockerBase. "-v /:/local "}
	  	push (@newTokens,"$dockerBase @execs ");
			}
			else{
				push (@newTokens,"@execs");
			}	
	 }	
	 else{
		 $token =~ s/stdin\:\:/\</;			
			push(@newTokens,$token);
	 }	
 }
 my @dockerTokens;
 foreach my $i (0..$#newTokens){
  push(@dockerTokens,$newTokens[$i]);
	 if($i <$#newTokens){
	 	push(@dockerTokens,$ops[$i]);
	 }
 }	
 my $dcmd=join("",@dockerTokens);
 if($verbose){print STDERR "Processed command is:\n$dcmd\n";}
 system("$dcmd");
}
sub findTokensOps{
 my ($cmd,$delim,$tokens,$ops)=@_;
 @{$tokens}=quotewords($delim,1,$cmd);
 #find all the ops in between - this avoids finding ops inside quotes
 my $start=0;
 if(@{$tokens}){
  foreach my $i (0..$#{$tokens}-1){
	 	my $tokenA=quotemeta($tokens->[$i]);
	 	my $tokenB=quotemeta($tokens->[$i+1]);
	 	my $string=substr($cmd,$start);
	 	my ($op)= $string =~  m/$tokenA(.*)$tokenB/;
	 	push(@{$ops},$op);
	 	$start+=length($tokens->[$i])+length($op);
	 }
	 #check if there is a trailing op like &
	 #in the future change the wrapper from --rm to -d for background processes 
	 $start+=	length($tokens->[-1]);
  if($start < length($cmd)){
	 	my $op = substr($cmd,$start);
	 	if($op =~ /([\|\>\&\<]+)/){
		 	push(@{$ops},$1);
		 }
		}	
	}
}
