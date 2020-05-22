proc dbg {str} {
	set curr [.console cget -text]
	if {$curr eq ""} {
		.console configure -text "$str"
	} else {
		.console configure -text "$curr\n$str"
	}
}

proc dbg_clear {} {
	.console configure -text ""
}

# Tooltips can have as many tags as you need.
# The first tag should always be a unique identifier for the tooltip!
# all tooltips will receive a "tooltip" tag
#
# The colors are passed TK style using
#	-textcolor
#	-bkg
#	-outline
# see:
# https://stackoverflow.com/questions/29150599/call-tcl-proc-with-named-arguments
proc create_tooltip {mytoplevel x y text tags args} {
	set uniqueTag [lindex $tags 0]
	set textTags "$tags tooltip"
	set bkgTags "$tags tooltipBkg"

	array set optional [list -textcolor "blue" -bkg "white" -outline "blue" -anchor center {*}$args]
	set textcolor $optional(-textcolor)
	set bkg $optional(-bkg)
	set outline $optional(-outline)

    set textId [$mytoplevel create text $x $y -text $text -tags $textTags -fill $textcolor]

    # the tag arg passed to bbox should be a single tag or a tag expression
    # set boundingBox [$mytoplevel bbox {tooltip || tooltipBkg}]

    set boundingBox [$mytoplevel bbox $textId]
    set bkgId [$mytoplevel create rect $boundingBox -fill $bkg -outline $outline -tags $bkgTags]
    $mytoplevel lower "tooltipBkg"

    if {$optional(-anchor) eq "left" || $optional(-anchor) eq "right"} {
    	set tooltip_w [expr {[lindex $boundingBox 2]-[lindex $boundingBox 0]}]
    	set sign [expr {$optional(-anchor) eq "left" ? 1 : -1}]
    	.c move $textId [expr {$sign*$tooltip_w/2}] 0
    	.c move $bkgId [expr {$sign*$tooltip_w/2}] 0
    }

    button .test.del_btn_$textId -text "delete $text using textId: $textId" -command ".c delete $textId;.c delete $bkgId;"
    button .test.del_btn_tag_$textId -text "delete $text using unique tags: $uniqueTag" -command "delete_tooltips $uniqueTag"

    grid .test.del_btn_$textId -row [expr {$textId+1}] -column 0
    grid .test.del_btn_tag_$textId -row [expr {$textId+1}] -column 1

}

proc initialize_windows {} {
	# window that will display the tooltips
	canvas .c -background #ffffff

	label .console
	.console configure -text ""
	bind . <Key-Escape> exit
	bind . <Key-BackSpace> clear_tooltips

	pack .c
	pack .console
	wm geometry . +0+0

	initialize_test_window
	initialize_tooltips

	set w [.c cget -width]
	set h [.c cget -height]
}

proc initialize_tooltips {} {
	set w [.c cget -width]
	set h [.c cget -height]

	# left ones
	create_tooltip .c [expr $w/2-125] 50  left_A {left_A_TAG left}
	create_tooltip .c [expr $w/2-125] 100 left_B {left_B_TAG left}
	create_tooltip .c [expr $w/2-125] 150 left_C {left_C_TAG left} -outline #00ff00
	create_tooltip .c [expr $w/2-125] 200 left_D {left_D_TAG left} -textcolor red
	create_tooltip .c [expr $w/2-125] 250 left_E {tooltip_E_TAG left} -bkg black -textcolor white -outline red

	# right ones
	create_tooltip .c [expr $w/2+125] 50  "right_A" "right_A_TAG right"
	create_tooltip .c [expr $w/2+125] 100 "right_B" "right_B_TAG right"
	create_tooltip .c [expr $w/2+125] 150 "right_C" "right_C_TAG right"
	create_tooltip .c [expr $w/2+125] 200 "right_D" "right_D_TAG right"
	create_tooltip .c [expr $w/2+125] 250 "right_E" "right_E_TAG right"

	# middle ones
	.c create line [expr $w/2] 0 [expr $w/2] $h -fill black
	create_tooltip .c [expr $w/2] [expr $h/2+50] "anchor_right" "anchor_right_TAG" -anchor right
	create_tooltip .c [expr $w/2] [expr $h/2] "anchor_center" "anchor_center_TAG" -anchor center
	create_tooltip .c [expr $w/2] [expr $h/2-50] "anchor_left" "anchor_left_TAG" -anchor left

	.c bind "tooltip" <ButtonPress> {dbg "[find_tooltip_by_pos %x %y]"}
}

proc initialize_test_window {} {
	#window with the commands
	toplevel .test
	bind .test <Key-Escape> exit
	#button .test.restart -text "restart" -command {initialize_tooltips}
	button .test.restart -text "restart" -command {restart}

	# needed to get correct info
	update

	wm geometry .test +[winfo width .]+0

	button .test.del_left -text "delete left" -command {delete_tooltips "left"}
	button .test.del_right -text "delete right" -command {delete_tooltips "right"}

	label .test.helptext -text "click tooltips!\nPress Escape to quit"

	grid .test.restart -row 0 -column 0
	grid .test.helptext -row 0 -column 1
	grid .test.del_left -row 1 -column 0
	grid .test.del_right -row 1 -column 1
}

# deletes all tooltips with the given tag
proc delete_tooltips {tag} {
	.c delete $tag
}

proc clear_tooltips {} {
	dbg "BackSpace pressed. Tooltips cleared!"
	delete_tooltips "tooltip"
}

proc find_tooltip_by_pos {x y} {
	set all [.c find all]
	foreach i $all {
    	set bbox [.c bbox $i]
    	set x1 [lindex $bbox 0]
    	set y1 [lindex $bbox 1]
    	set x2 [lindex $bbox 2]
    	set y2 [lindex $bbox 3]
    	if {$x >= $x1 && $x <= $x2 && $y >= $y1 && $y <= $y2} {
    		lappend hit $i
    		if {[.c type $i] eq "text"} {
				return [.c itemcget $i -text]
    		}
    	}
	}
	return "not found"
}

proc restart {} {
	.c delete all
	destroy .test
	dbg_clear
	initialize_test_window
	initialize_tooltips
	#focus .test
	raise .
}

initialize_windows
