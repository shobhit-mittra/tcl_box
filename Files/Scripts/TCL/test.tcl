proc read_sdc {arg1} {
set sdc_dirname [file dirname $arg1]
set sdc_filename [lindex [split [file tail $arg1] .] 0 ]
set sdc [open $arg1 r]
set tmp_file [open /tmp/1 w]
puts "sdc_dirname is $sdc_dirname"
puts "arg1 is $arg1"
puts "part1 is [file tail $arg1]"
puts "part2 is [split [file tail $arg1] .]"
puts "part3 is [lindex [split [file tail $arg1] .] 0 ]"
puts "sdc_filename is $sdc_filename"

puts -nonewline $tmp_file [string map {"\[" "" "\]" " "} [read $sdc]]     
close $tmp_file

#-----------------------------------------------------------------------------#
#----------------converting create_clock constraints--------------------------#
#-----------------------------------------------------------------------------#

set tmp_file [open /tmp/1 r]
set timing_file [open /tmp/3 w]
set lines [split [read $tmp_file] "\n"]
puts $lines
set find_clocks [lsearch -all -inline $lines "create_clock*"]
puts $find_clocks
foreach elem $find_clocks {
	set clock_port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
	puts "part1 is [lsearch $elem "get_ports"]"
	puts "part2 is [expr {[lsearch $elem "get_ports"]+1}]"
	puts "part3 is $clock_port_name"
	puts "clock_port_name is $clock_port_name"
	set clock_period [lindex $elem [expr {[lsearch $elem "-period"]+1}]]
	puts "cp_part1 is [lsearch $elem "-period"]"
	puts "cp_part2 is [expr {[lsearch $elem "-period"]+1}]"
	puts "cp_part3 is $clock_period"
	puts "clock_period is $clock_period"
	set duty_cycle [expr {100 - [expr {[lindex [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]] 1]*100/$clock_period}]}]
	puts "dc_part1 is [lsearch $elem "-waveform"]"
	puts "dc_part2 is [expr {[lsearch $elem "-waveform"]+1}]"
	puts "dc_part3 is [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]]"
	puts "dc_part4 is [lindex [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]] 1]"
	puts "dc_part5 is [expr {[lindex [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]] 1]*100/$clock_period}]"
	puts "dc_part6 is $duty_cycle"
	puts "duty_cycle is $duty_cycle"
	puts $timing_file "clock $clock_port_name $clock_period $duty_cycle"
	puts "clock $clock_port_name $clock_period $duty_cycle\n"
	}
close $tmp_file

#-----------------------------------------------------------------------------#
#----------------converting set_clock_latency constraints---------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_clock_latency*"]
puts  $find_keyword
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1}]]
	puts "pn_part1 is [lsearch $elem "get_clocks"]"
	puts "pn_part2 is [expr {[lsearch $elem "get_clocks"]+1}]"
	puts "pn_part3 is $port_name"
	puts "port_name is $port_name"
	if {![string match $new_port_name $port_name]} {
        	set new_port_name $port_name
		puts "dont match"
		puts "new_port_name changed to $new_port_name" 
        	set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
		puts "dl_part1 is [list "*" " " $port_name " " "*"]"
		puts "dl_part2 is [join [list "*" " " $port_name " " "*"] ""]"
		puts "delays_list is $delays_list"
        	set delay_value ""
        	foreach new_elem $delays_list {
        		set port_index [lsearch $new_elem "get_clocks"]
			puts "old delay_value is $delay_value"
			puts "port_index is $port_index"
        		lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
			puts "new delay_value $delay_value"
        	}
        	puts "entering"
		puts -nonewline $tmp2_file "\nat $port_name $delay_value"
		puts "at $port_name $delay_value\n"
	}
}

close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file

#-----------------------------------------------------------------------------#
#----------------converting set_clock_transition constraints------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_clock_transition*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1}]]
        if {![string match $new_port_name $port_name]} {
		set new_port_name $port_name
		set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        	puts "delays_list is $delays_list"
        	set delay_value ""
        	foreach new_elem $delays_list {
        		set port_index [lsearch $new_elem "get_clocks"]
        		lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        	}
        	puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
	}
}

close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file

#-----------------------------------------------------------------------------#
#----------------converting set_input_delay constraints-----------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_input_delay*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
        if {![string match $new_port_name $port_name]} {
                set new_port_name $port_name
        	set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        	puts "delays_list is $delays_list"
		set delay_value ""
        	foreach new_elem $delays_list {
        		set port_index [lsearch $new_elem "get_ports"]
        		lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        	}
        	puts -nonewline $tmp2_file "\nat $port_name $delay_value"
	}
}
close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file

#-----------------------------------------------------------------------------#
#----------------converting set_input_transition constraints------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_input_transition*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
        if {![string match $new_port_name $port_name]} {
                set new_port_name $port_name
        	set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
                puts "delays_list is $delays_list"
        	set delay_value ""
        	foreach new_elem $delays_list {
        		set port_index [lsearch $new_elem "get_ports"]
        		lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        	}
        	puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
	}
}

close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file

#-----------------------------------------------------------------------------#
#---------------converting set_output_delay constraints-----------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_output_delay*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
        if {![string match $new_port_name $port_name]} {
                set new_port_name $port_name
        	set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        	set delay_value ""
        	foreach new_elem $delays_list {
        		set port_index [lsearch $new_elem "get_ports"]
        		lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        	}
        	puts -nonewline $tmp2_file "\nrat $port_name $delay_value"
	}
}

close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file

#-----------------------------------------------------------------------------#
#-------------------converting set_load constraints---------------------------#
#-----------------------------------------------------------------------------#

set find_keyword [lsearch -all -inline $lines "set_load*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""
foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
        if {![string match $new_port_name $port_name]} {
                set new_port_name $port_name
        	set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*" ] ""]]
        	set delay_value ""
        	foreach new_elem $delays_list {
        	set port_index [lsearch $new_elem "get_ports"]
        	lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        	}
        	puts -nonewline $timing_file "\nload $port_name $delay_value"
	}
}
close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file "[join [lsort -unique [split [read $tmp2_file] \n]] \n]"
close $tmp2_file

#-----------------------------------------------------------------------------#
close $timing_file

set ot_timing_file [open $sdc_dirname/$sdc_filename.timing w]
puts "sdc_dirname is $sdc_dirname"
puts "sdc_filename is $sdc_filename"
puts "ot_timing_file is $ot_timing_file"
set timing_file [open /tmp/3 r]
while {[gets $timing_file line] != -1} {
        if {[regexp -all -- {\*} $line]} {
                set bussed [lindex [lindex [split $line "*"] 0] 1]
		puts "bussed is $bussed in \"$line\""
                set final_synth_netlist [open $sdc_dirname/$sdc_filename.final.synth.v r]
                while {[gets $final_synth_netlist line2] != -1 } {
                        if {[regexp -all -- $bussed $line2] && [regexp -all -- {input} $line2] && ![string match "" $line]} {
			puts "bussed $bussed matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"
			puts "string \"input\" found in $line2"
			puts "null string \"\" doesn't match $line in $timing_file"
                        puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
			puts "ot_part1 is [split $line "*"]"
			puts "input_ot_part1 is [lindex [lindex [split $line "*"] 0 ] 0 ]"
			puts "input_ot_part2 is [lindex [lindex [split $line2 ";"] 0 ] 1 ]"
			puts "input_ot_part3 is [lindex [split $line "*"] 1 ]"
			puts "input_ot_part is [lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
                        } elseif {[regexp -all -- $bussed $line2] && [regexp -all -- {output} $line2] && ![string match "" $line]} {
			puts "string \"output\" matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"
                        puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
			puts "output_ot_part is [lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
                        }
                }
        } else {
        puts -nonewline $ot_timing_file  "\n$line"
        }
}

close $timing_file
puts "set_timing_fpath $sdc_dirname/$sdc_filename.timing"
}
set working_dir [exec pwd]
read_sdc $working_dir/outdir_openMSP430/openMSP430.sdc
