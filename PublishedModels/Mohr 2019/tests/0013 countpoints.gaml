model countpoint

global {

	// set general values of the simulation
	float step <- 92 #s;												// simulation timestep in seconds, 300
	int refresh_map_every <- 1;									// update map every X cycles, 1
	int refresh_monitor_every <- 1;							// update map every X cycles, 1
	int refresh_chart_every <- 1;								// update map every X cycles, 1
	float minimum_cycle_duration<- 1.0;					// whats the minimum time of a cycle? 1.0
	list<int> touringcompanys_members_weighted_list <- [14,24,19,14,9,5,5,4,2,2,1,1];	// 1...12 members

	string pause_condition <- 'allathome'				// pause the model if a special condition is reached
		among:["allathome","endless","endafterdays"];

 	// set model parameters 
	int number_of_touringcompanys <- 1;						// number of paralell touringcompanys
	int maximum_range_touringcompany <- 8000;		// possible average one-way distance (m) of targets (POIs) for a touringcompany to go for
	float touringcompanys_speed <- 1.2 #m/#s;				// standard hikingspeed of touringcompanys 
	float touringcompanys_speed_sdev <- 0.5 #m/#s;	// SDEV for standard hikingspeed of touringcompanys 
	
	// load the shape data for this world
	file bounds_shapefile <- file("../includes/TESTS/testarea_new_v1_bounds.shp");
	file ways_shapefile <- file("../includes/TESTS/testarea_new_v1_ways.shp");
	file parking_shapefile <- file("../includes/TESTS/testarea_new_v2_parking.shp");
	file pois_shapefile <- file("../includes/TESTS/testarea_new_v2_pois.shp");
	file countingpoint_shapefile <- file("../includes/TESTS/testarea_new_v2_countpoint.shp");
	geometry shape <- envelope(bounds_shapefile);

	// set visual parameters
	rgb ways_color <- rgb(128, 128, 128,255);
	int ways_symbol_size <- 5;
	rgb parking_color <- rgb (0, 128, 255,255);
	int parking_symbol_size <- 50;
	rgb pois_color <- rgb (255, 128, 255,255);
	int pois_symbol_size <- 50;
	rgb touringcompanys_color_setup <- rgb (255, 157, 157,255);
	rgb touringcompanys_color_hikingtarget <- rgb (255, 0, 0,255);
	rgb touringcompanys_color_target <- rgb (0, 128, 0,255);
	rgb touringcompanys_color_hikinghome <-rgb (249, 81, 0,255);
	rgb touringcompanys_color_home <- rgb (192, 192, 192,255);
	int touringcompanys_symbol_size <- 20;
	
	// set map GUI parameters
	bool show_touringcompany_names <- false;		// show names at every touringcompany
	bool show_linetotarget <- false;								// draw a line from the touringcompany to the target
	bool show_poi_id <- false;										// show the IDs of the POIs
	bool show_parking_id <- false;								// show the IDs of the parking-areas
	int label_offset <- 20;												// xy-offset for labeling species
	
	// generate a global (network) graph
    graph ways_graph;
	map<ways,float> weights_map <- nil;														
    
	init {

		create ways from: ways_shapefile with: [
				shape_objectid::int(read('OBJECTID'))
			] {	name <- "ID-" + string(shape_objectid); }
		weights_map <- ways as_map (each:: each.shape.perimeter); 
		ways_graph <- as_edge_graph (ways) with_weights weights_map with_optimizer_type 'Djikstra' use_cache true;

		create parking from: parking_shapefile with: [
				shape_objectid::int(read('OBJECTID')),
				shape_attraction::string(read('Attrakt'))
			] {	name <- "ID-" + string(shape_objectid); }

		create pois from: pois_shapefile with: [
				shape_objectid::int(read('OBJECTID')),
				shape_attraction::string(read('Attrakt'))
			] {	name <- "ID-" + string(shape_objectid); }

		create countingpoint from: countingpoint_shapefile with: [
				shape_objectid::int(read('OBJECTID'))
			] {
				name <- "ID-" + string(shape_objectid);
			}

		create touringcompanys number: number_of_touringcompanys {
			list<parking> possibleparkingareas <- (parking) ;
			touringcompanys_home <- one_of(parking);
			touringcompanys_members <- get_random_value_of_weighted_list (touringcompanys_members_weighted_list);
			touringcompanys_status <- 'setup';
			location <- touringcompanys_home;
			speed <- truncated_gauss({touringcompanys_speed,touringcompanys_speed_sdev});
			touringcompanys_id <- copy_between(name,15,999);
			ask parking(touringcompanys_home) {
				count_touringcompanys_home <- count_touringcompanys_home + 1; 
				count_touringcompanys_members_home <- count_touringcompanys_members_home + myself.touringcompanys_members; 
			}
		}

	}

	// --> one cycle behind screen!!!
	reflex caculate_and_output_values { 
		ask ways {
			if cycle > 0 {
				avg_tc_on_way <- sum_tc_on_way / (cycle);
				if (tc_on_way > max_tc_on_way) {max_tc_on_way <- tc_on_way;}
			}
		}
	}


	reflex halt_the_model {
		if (pause_condition = 'allathome') {
			if touringcompanys count (each.touringcompanys_status = 'home') = number_of_touringcompanys {
				do pause;	
			}
		}
	}

}


species countingpoint {
	int shape_objectid <- nil;
	int tc_at_countingpoint <- 0;

	aspect base {
		draw geometry:square(50) color:#aquamarine;
		draw string(shape_objectid) color:#black size: 4 at:point(self.location.x,self.location.y);
	}
}

species ways  {
	int shape_objectid;

	float tc_on_way <- 0 update: 0;
	float sum_tc_on_way <- 0;
	float avg_tc_on_way <- 0;
	float max_tc_on_way <- 0;

	aspect base {
		draw (shape + ways_symbol_size) color:ways_color;
		draw string(shape_objectid) + " | " + string(tc_on_way with_precision 2) + " | " + string(sum_tc_on_way with_precision 2)  + " | " + string(max_tc_on_way with_precision 2) color: #black;
	}
}


species parking  {
	int shape_objectid; 
	int shape_attraction;

	int count_touringcompanys_home <- nil;
	int count_touringcompanys_members_home <- nil;
	
	aspect base {
		draw geometry:square(parking_symbol_size) color:parking_color;
		if show_parking_id {
			draw string(shape_objectid) color: #black size: 6 at:point(self.location.x,self.location.y);
		}
	}
}


species pois  {
	int shape_objectid; 
	int shape_attraction; 

	int count_touringcompanys_at_target <- nil;
	int count_touringcompanys_members_at_target <- nil;
	
	aspect base {
		draw geometry:triangle(pois_symbol_size) color:pois_color;
		if show_poi_id {
			draw string(shape_objectid) color: #black size: 4 at:point(self.location.x,self.location.y);
		}
	}
}


species touringcompanys skills:[moving] {
	int touringcompanys_members <- nil;
	point touringcompanys_target <- nil;
    agent touringcompanys_target_agent <- nil;
	point touringcompanys_home <- nil;
    path shortest_path <- nil;
	string touringcompanys_status <- nil;
    float hiked_distance <- nil;
    string touringcompanys_id <- nil; 

	reflex move_touringcompany {
		
		if (touringcompanys_status = 'setup') {
			touringcompanys_target_agent <- one_of(pois at_distance maximum_range_touringcompany);
			touringcompanys_target <- touringcompanys_target_agent;
			touringcompanys_status <- 'hikingtarget';
		}

		if (touringcompanys_status = 'target') {
			touringcompanys_target <- touringcompanys_home;
			touringcompanys_status <- 'hikinghome';
		}

		if (touringcompanys_status = 'hikingtarget' and touringcompanys_target = location and location != touringcompanys_home) {
			touringcompanys_target <- nil ;
			touringcompanys_status <- 'target';
			ask pois(touringcompanys_target_agent) {
				count_touringcompanys_at_target <- count_touringcompanys_at_target + 1; 
				count_touringcompanys_members_at_target <- count_touringcompanys_members_at_target + myself.touringcompanys_members; 
			}
		}
		
		if (touringcompanys_status = 'hikinghome' and touringcompanys_target = location and location = touringcompanys_home) {
			touringcompanys_target <- nil ;
			touringcompanys_status <- 'home';
		}

		path path_followed <- goto (target: touringcompanys_target, on: ways_graph, recompute_path:false, speed:speed, return_path: true);

		if (touringcompanys_target != nil) {
			shortest_path <- path_between (ways_graph,location,touringcompanys_target);
		} else {
			shortest_path <- nil;
		}	

		if (path_followed.shape != nil ) {
			hiked_distance <- hiked_distance + path_followed.shape.perimeter;
		}

		loop linesegments over: path_followed.segments {
				ask ways(path_followed agent_from_geometry linesegments) { 
					tc_on_way <- tc_on_way + 1 * (linesegments.perimeter / path_followed.shape.perimeter);
					sum_tc_on_way <- sum_tc_on_way + 1 * (linesegments.perimeter / path_followed.shape.perimeter);
				}
		}




		list list_countingpoint_passed <- nil;
		loop linesegments over: path_followed.segments {
			list countingpoints_passed <- inside(countingpoint,linesegments);
			loop countingpoint_passed over:countingpoints_passed {
					write heading;
				if not (list_countingpoint_passed contains countingpoint_passed) {
					countingpoint[countingpoint_passed].tc_at_countingpoint <- countingpoint[countingpoint_passed].tc_at_countingpoint + 1; 
					add countingpoint_passed to: list_countingpoint_passed;
				}
			}
		}



	}
	 
	aspect base {

		if (touringcompanys_status = 'setup') {
				draw circle(touringcompanys_symbol_size) color:touringcompanys_color_setup;

			} else if (touringcompanys_status = 'hikingtarget') {
				draw circle(touringcompanys_symbol_size) color:touringcompanys_color_hikingtarget;
				if show_touringcompany_names {
					draw string(touringcompanys_id) color: #black size: 3 at:point(self.location.x+label_offset,self.location.y-label_offset);
				}

			} else if (touringcompanys_status = 'target') {
				draw circle(touringcompanys_symbol_size) color:touringcompanys_color_target;
				if show_touringcompany_names {
					draw string(touringcompanys_id) color: #black size: 3 at:point(self.location.x+label_offset,self.location.y-label_offset);
				}

			} else if (touringcompanys_status = 'hikinghome') {
				draw circle(touringcompanys_symbol_size) color:touringcompanys_color_hikinghome;
				if show_touringcompany_names {
					draw string(touringcompanys_id) color: #black size: 3 at:point(self.location.x+label_offset,self.location.y-label_offset);
				}

			} else if (touringcompanys_status = 'home') {
				draw circle(touringcompanys_symbol_size) color:touringcompanys_color_home;
		}

		if (show_linetotarget and touringcompanys_target != nil) {
			draw polyline([self.location,touringcompanys_target]) color:#blue;
		}

	}

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


experiment countpoint_experiment type: gui {
	float minimum_cycle_duration <- minimum_cycle_duration;
	user_command "countingpoint" action:summarize_countingpoint;

	parameter "Number:" var: number_of_touringcompanys category: "Touringcompanys";
	parameter "Speed (m/s):" var: touringcompanys_speed category: "Touringcompanys";
	parameter "SDEV speed (m/s):" var: touringcompanys_speed_sdev category: "Touringcompanys";
	parameter "Max one-way range:" var: maximum_range_touringcompany category: "Touringcompanys";
	parameter "Members weighted list:" var: touringcompanys_members_weighted_list category: "Touringcompanys";
	parameter "Timestep-increment [s]:" var: step category: "Simulation";
	parameter "Pause condition:" var: pause_condition category: "Simulation";
	parameter "Cycle duration [s]:" var: minimum_cycle_duration category: "Simulation";
	parameter "SHOW line to target:" var: show_linetotarget category: "Map";
	parameter "SHOW touringcompany name:" var: show_touringcompany_names category: "Map";
	parameter "SHOW POI IDs" var: show_poi_id category: "Map";
	parameter "SHOW parking-area IDs" var: show_parking_id category: "Map";

	output {
		display "Map Simulation" refresh:every(refresh_map_every) type:opengl {
				species countingpoint aspect: base refresh: true;
				species parking aspect: base refresh: true;
				species pois aspect: base refresh: true;
				species ways aspect: base refresh: true;
				species touringcompanys aspect: base refresh: true;
			}
	}

	action summarize_countingpoint {
		loop i from: 0 to: (length(countingpoint)-1) {
			write "i=" + string(i) + " --> objectid=" + countingpoint[i].shape_objectid + " TCatcountingpoint=" + countingpoint[i].tc_at_countingpoint;
		}
	}

}
