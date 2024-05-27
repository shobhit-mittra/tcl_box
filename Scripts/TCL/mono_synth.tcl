#TCL Script for Mono-TCL Box

# Extracting input csv file from arv list and creating a file handle for it 
set filename [lindex $argv 0]
set inID [open "$filename" r]

set outID [open "debug.txt" w]

# Defining a dictionary for pattern to be used in regexp
set patterns {
	{Design Name,(.*)} "designName"
	{Output Directory,(.*)} "Output_Directory"
	{Netlist Directory,(.*)} "Netlist_Directory" 
	{Early Library Path,(.*)} "Early Cell Lib"
	{Late Library Path,(.*)} "Late Cell Lib"
	{Constraints File,(.*)} "Constraint_File"
}

# Creating an empty dictionary
set extr_info [dict create]
global extr_info

while { ![eof $inID] } {
	gets $inID line

	#Iterating through the patterns
	foreach {pattern description} $patterns {
		if { [regexp "$pattern" $line -> match] } {
			# Defining key-value pair in the dictionary 
			dict set extr_info $description $match
			break ; # Break out of the loop as soon as match is found
		}
	}
}

#----------------------------------------------#
# Assigning variables to the captured values 
#----------------------------------------------#
foreach key [dict keys $extr_info] {
	#Creating variable same name as the key
	upvar 0 $key var
	set var [dict get $extr_info $key]	
}


#-----------------------------------------------------------------------------#
# Checking if the directories exist from the extracted paths in the csv file
#-----------------------------------------------------------------------------#
set keys [dict keys $extr_info]
set startIndex [lsearch $keys "Output_Directory"]

# Exclude 'Design Name' key from the search space of keys
set updateKeys [lrange $keys $startIndex end]

foreach key $updateKeys {
	set value [dict get $extr_info $key]

	# Checking specifically for directories (Using isdirectory option in file command)
	if { $key == [lindex $keys 1] || $key == [lindex $keys 2] } {
		if { $key == [lindex $keys 1] } { 
			if {! [file isdirectory  $value] } {
				puts "\nError : Cannot find $key in the path : $value. Creating Directory ....."
				file mkdir $value 
			} else {
				puts "\nInfo : $key is found in the path : $value."
				
			}

		} else {
			if {! [file isdirectory  $value] } {
				puts "\nError : Cannot find $key in the path : $value. Exiting ....."
				exit
		
			} else {
				puts "\nInfo : $key is found in the path : $value."
			}
		}

	# Checking the files now using the exists option in the file command	
	} else {
		if {![file exists $value]} {
			puts "\nError : The file $key does not exist in the path : $value. Exiting ....."
			exit
		
		} else {
			puts "\nInfo : File $key found in the path : $value"
		}	
	}
}


#--------------------------------------------------------------------#
# Reading the 'Constrant File' and converting it into SDC format :
#--------------------------------------------------------------------#

# Creating file handle to read the 'Constraint File'
set constraintsID [open "$Constraint_File" r]
seek $constraintsID 0 start ; # Making sure file pointer points at the start of the file

# Creating file handle to dump the processed Constraint File as an SDC file
set sdcFile "$Output_Directory/constraints.sdc"
set sdcID [open $sdcFile w]

# Creating a global dictionary to hold attribute key-value pair
set global_attr [dict create]
global global_attr

# Creating a division holding variable
set currentDiv ""
global currentDiv 

# Function to remove white space elements in a list
proc ls_clean {myList} {

	set modList ""

	foreach elem $myList {
		if {"$elem" ne ""} {
			lappend modList $elem
		}
	}	

	return $modList
}

# Creating a pattern for divison dictionary : IMP!  Please make changes to this dictionary according to the pattern matching in your constraints file 
set div_dict {
	{^CLOCKS} "ck"
	{^INPUTS} "in"
	{^OUTPUTS} "out"
}

# Initialising a div-key variable
set divKey ""
global divKey

set conCount 0
global conCount

# Create a continue flag variable
set contFlag 0
global contFlag

# Create a condition met variable
set condMet 0
global condMet

# Create a check complete variable
set checkComp 0
global checkComp

# Extracting content from constraints file
while {![eof $constraintsID]} {

	gets $constraintsID line

	foreach con $line {
		# Setting attribute list and variable
		foreach {pattern divKey} $div_dict {
			if {[regexp "$pattern" $con]} {
				set divKey $divKey
				set attr [split $con ","]
				set clean_attr [ls_clean $attr]
				global clean_attr
				
				# Pushing the division key and it's pair into the global attribute dictionary
				dict set global_attr $divKey $clean_attr

				# Dynamically create array variable
				set arrayName "$divKey"

				# Setting the array
				array set $arrayName {}
		
				# Reference the dyanmic array variable
				upvar #0 $arrayName arrayRef


				# set the continue flag to get to the top of while loop
				set contFlag 1

				# set condition met flag to 1 if a match is found
				set condMet 1
				
				# Break out of innermost foreach
				break
			
			} else {
				# Check if last item in the div_dict is reached or not
				if {$divKey eq [lindex $div_dict end]} {
					# set continue flag to zero to go further into the outtermost foreach loop
					set contFlag 0

					# set the check complete flag to 1
					set checkComp 1

					# set the condition met flag to 0 since conditions arent met
					set condMet 0

					# Break outta innermost foreach
					break

				}
			}
			
		}

		if {$contFlag} {
			# Break out of ouutermost foreach loop
			break
		}

		if {! $condMet && $checkComp} {
			
		set col [split $con ","]
		set clean_col [ls_clean $col]
		global clean_col


		if {[lindex $clean_col 0] ne ""} {
			set colIndex 0
			
			foreach attr $clean_attr {
				set arrayRef($conCount,$attr) [lindex $clean_col $colIndex]
				incr colIndex			
			}	 

			incr conCount
					
			set contFlag 1
			break	
				
		} else {
			set conCount 0
					
			set contFlag 1
			break
		}

		# Check for continue flag status
		if { $contFlag } {
			# Break outta outtermost foreach
			break
		}
	
		} ; # close brace of condition control if 
	} 	; # close brace of outtrmost foreach

	# Check for continue flag status
	if { $contFlag } {
		# Reach to the top of the while loop
		continue
	}
	
}	; # close brace of while loop


puts "\nProcessing successful ! Dumping the constraints to create the SDC file. Check the output directory created at the path : $Output_Directory for the generated constraints.sdc ....."

# Dumping the extracted inforamtion into SDC file 

# Creating a function to process the pattern present in the verilog files in the verilog directory and modify it if required to incorporate for the bus
proc mod_pattern {dirPath pattern searchParam count} {
	

	# Setting an identifier for in/out attribute 
	if { $searchParam eq "input"} {
		set identifier "in"
	
	} elseif { $searchParam eq "output"} {
		set identifier "out"
	
	} else {
		puts "\nError : Invalid Search-Pattern parameter provided as an argument. Valid parameters are : 'input' and 'output'. Exiting ....."
		
		return 

	}

	# Set a modified pattern name variable 
	set modPattern ""
	

	# Dynamically setting up attribute name using identifier 
	set varName "${identifier}"
	upvar #0 $varName var
	
	# Extracting the value held by the attribute pattern (INPUTS/OUTPUTS) 
	set attr_value $var($count,$pattern)
		
	# Get list of .v files in a directory
	set verilog_ls [glob -nocomplain -directory $dirPath *.v]

	if {[llength $verilog_ls] == 0} {
		puts "\nError : No Verilog files present in the directory : $dirPath. Kindly check the path and retry. Exiting ....."
		
		return
	}
	

	foreach files $verilog_ls {
		set fileID [open "$files" r]
		
		while {![eof $fileID]} {

			gets $fileID line
			
			if {[regexp "^$searchParam" $line]} {
			
				if {[regexp $attr_value $line]} {
					set line [split $line ";"]
				
					set line [lindex $line 0]
					puts "$line found in the path : ${dirPath}/${files}"
				

					# Grabbing the input directive from verilog syntax in the line
					if {[regexp "$searchParam" [lindex $line 0]]} {
						# Clearing all the spaces using ls_clean function
						set clean_line [ls_clean $line]
						puts "Cleaned line : $clean_line and length of line : [llength $clean_line]"

						# Check for length of captured line element, a value greater than 2 shall indicate the presence of a bus
						if {[llength $clean_line] > 2} {
							# Modify the name of the pattern to incorporate for the bus
							append modPattern $var($count,$pattern) "*"
							puts "modified name : $modPattern"
	
						} else {
							set modPattern $var($count,$pattern)
					       		puts "no change : $modPattern"	
						}

					}	
				}

			}	

		close $fileID

		}
	}		

	return $modPattern

}


# Creating a function to extract attributes from list provided as an argument and setting variables for further processing
proc get_attr {myList identifier} {

	foreach elem $myList {
		set varName "${identifier}_${elem}_attr"
		
		upvar 1 $varName var
		
		set var $elem 
	
	}
}

# Accessing the global attribute dictionary
foreach key [dict keys $global_attr] {
	# Setting a local clock count
	set itemCount 0
		
	# Choosing clock attributes specifically
	if {$key eq "ck"} {

		puts "\nINFO : Working on Clock Constraints ....."

		set ck_ls [dict get $global_attr $key]
		
		# Checking existance of variable in the ck array 
		while {[info exists ::ck($itemCount,[lindex $ck_ls 0])]} {

			# Extracting the attribute pointers from the ck_ls list
			get_attr $ck_ls "ck"
			
			## Creating clock constraints \
			# Mainly 2 types of constraints :
			# 	 create_clock -name <clock_name> -period <clock_period> -waveform {0 duty_cycle*0.01*clock_period} [get_ports <clock_name>]
			#	 set_clock_latency -rise/-fall -min/-max <value> [get_clocks <clock_name>]


			puts $sdcID "create_clock -name $ck($itemCount,$ck_CLOCKS_attr) -period $ck($itemCount,$ck_frequency_attr) -waveform {0 [expr {$ck($itemCount,$ck_frequency_attr) * $ck($itemCount,$ck_duty_cycle_attr) * 0.01}]} \[get_ports $ck($itemCount,$ck_CLOCKS_attr)\]"
			
			puts $sdcID "set_clock_latency -source -rise -min $ck($itemCount,$ck_early_rise_delay_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -source -fall -min $ck($itemCount,$ck_early_fall_delay_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -source -rise -max $ck($itemCount,$ck_late_rise_delay_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -source -fall -max $ck($itemCount,$ck_late_fall_delay_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			
			puts $sdcID "set_clock_latency -rise -min $ck($itemCount,$ck_early_rise_slew_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -fall -min $ck($itemCount,$ck_early_fall_slew_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -rise -max $ck($itemCount,$ck_late_rise_slew_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"
			puts $sdcID "set_clock_latency -fall -max $ck($itemCount,$ck_late_fall_slew_attr) \[get_clocks $ck($itemCount,$ck_CLOCKS_attr)\]"

			incr itemCount
		}
		
		
		puts "\nINFO : Done with clock constraints ....."


	# Considiering the remaining keys : in and out attributes
	} else {
		
		puts "\nINFO : Working on I/O Constraints ....."

		if {$key eq "in"} {
			set in_ls [dict get $global_attr $key]
		
		} else {
			set out_ls [dict get $global_attr $key]
		}
		
		# Processing input constraints information
		while {[info exists ::in($itemCount,[lindex $in_ls 0])]} {
			
			# Extracting the attribute pointers from in_ls list
			set in_name [lindex $in_ls 0]

			set in_name_mod [mod_pattern $Netlist_Directory $in_name "input" $itemCount]	; # Syntax for mod_pattern command : mod_pattern <directory_path_to_search> <pattern_to_search> <search_word_associated_in_verilog> <item_count>
			puts "mod name : $in_name_mod"


			if {$in_name eq $in_name_mod} {
				puts "\nINFO : input port : $in($itemCount,$in_name) is not a bus"
			
			} else {
				puts "\nINFO : input port : $in($itemCount,$in_name) is a bus"
			}

			# Designating the pointer attributes from in_ls list
			get_attr $in_ls "in"

			# Input constraints : 
			# 	set_input_delay -clock [get_clocks <clock_name>] -min/-max -rise/-fall -source_latency_included <value> [get_ports <input_port>] 
			# 	set_input_transition -clock [get_clocks <clock_name>] -min/-max -rise/-fall -source_latency_included <value> [get_ports <input_port>] 		

			
			puts $sdcID "set_input_delay -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -min -rise -source_latency_included $in($itemCount,$in_early_rise_delay_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"
			puts $sdcID "set_input_delay -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -min -fall -source_latency_included $in($itemCount,$in_early_fall_delay_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
			puts $sdcID "set_input_delay -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -max -rise -source_latency_included $in($itemCount,$in_late_rise_delay_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
			puts $sdcID "set_input_delay -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -max -fall -source_latency_included $in($itemCount,$in_late_fall_delay_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	

			puts $sdcID "set_input_transition -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -min -rise -source_latency_included $in($itemCount,$in_early_rise_slew_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
			puts $sdcID "set_input_transition -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -min -fall -source_latency_included $in($itemCount,$in_early_fall_slew_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
			puts $sdcID "set_input_transition -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -max -rise -source_latency_included $in($itemCount,$in_late_rise_slew_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
			puts $sdcID "set_input_transition -clock \[get_clocks $in($itemCount,$in_clocks_attr)\] -max -fall -source_latency_included $in($itemCount,$in_late_fall_slew_attr) \[get_ports $in($itemCount,$in_INPUTS_attr)\]"	
		
	
			incr itemCount
		}

	
	
	
	}
}




close $inID
close $constraintsID
close $sdcID

close $outID
