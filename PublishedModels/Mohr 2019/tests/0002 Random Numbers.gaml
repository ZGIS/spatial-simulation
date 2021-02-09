model random_values

global {

	init {
		list the_pois <- ['Brocken','Torfhaus','Naturmythenpfad','Staumauer','Brockbahn'];
		list<int> the_pois_weighted_list <- [10,30,20,70,100];

		write sample (the_pois);
		write sample (the_pois_weighted_list);

		loop times: 50 {
			int random_weighted_poi <- get_random_value_of_weighted_list (the_pois_weighted_list);
			write string(random_weighted_poi) + " --> " + string(the_pois[random_weighted_poi]);
		}
	}


	// ---------------------------------------------------------------
	// ACTION to get the index of a random element of a weighted list 
	// ---------------------------------------------------------------
	action get_random_value_of_weighted_list (list<int> the_arguments) {
		//initilize variables
		list<int> the_list; int index_val <- nil;
 		// build the list with the limits
 		loop i from: 0 to: (length(the_arguments)-1) { add (the_arguments[i] + sum(copy_between(the_arguments,0,i))) to: the_list; }
		// generate a random number within 1 ... the_lists maximum
		int random_val <- rnd (max(the_list)-1) + 1;	
		// find the matching index-value of the original list
		loop index_val from: 0 to: (length(the_list)-1) { 	if (random_val <= the_list[index_val]) {break;} }
		// return the value (element)
		return index_val;
	}
	// ---------------------------------------------------------------

}





experiment random_values type: gui {
	output {
		display "Map" refresh:every(1) type:opengl {
		}
	}
}