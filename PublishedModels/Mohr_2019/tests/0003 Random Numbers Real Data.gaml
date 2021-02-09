model random_values_real_data

global {

	file shapefile <- file("../includes/NLP_Harz/investigationarea_pois_DHDN.shp");
	geometry shape <- envelope(envelope(shapefile));

	init {

		// create the POIs with all needed shapefile attributes
		create pois from: shapefile with: [
				shape_objectid::int(read('OBJECTID')),		// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),									// ID (primarykey)
				shape_type::string(read('Typ')),					// type of POI
				shape_name::string(read('name')),				// name of POI
				shape_attraction::string(read('Attrakt'))		// attraction of POI (how important is this POI?)
			]
			{
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " +self.shape_type + " " + shape_name;
		}

		list<int> pois_weighted_list <- pois collect each.shape_attraction;
		loop times: 200 {
			int random_weighted_poi <- get_random_value_of_weighted_list (pois_weighted_list);
			write string(random_weighted_poi) + " --> " + string(pois[random_weighted_poi]);
		}
	}


	// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// (global) ACTION to get the index of a random element of a weighted list 
	// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

}


species pois {

	int shape_objectid;
	int shape_id;
	string shape_type;
	string shape_name;
	int shape_attraction;

	aspect base {
		draw geometry:square(50) color:#red;
	}	
}







experiment random_values_real_data type: gui {
	output {
		display "Map" refresh:every(1) type:opengl {
		}
	}
}