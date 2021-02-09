model countareas

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
	int number_of_touringcompanys <- 50;						// number of paralell touringcompanys
	int maximum_range_touringcompany <- 8000;		// possible average one-way distance (m) of targets (POIs) for a touringcompany to go for
	float touringcompanys_speed <- 1.2 #m/#s;				// standard hikingspeed of touringcompanys 
	float touringcompanys_speed_sdev <- 0.5 #m/#s;	// SDEV for standard hikingspeed of touringcompanys 
	
	// load the shape data for this world
	string file_input <- "../includes/NLP_Harz/";
	file bounds_shapefile <- file(file_input + "investigationarea_bounds_DHDN.shp");
	file ways_shapefile <- file(file_input + "investigationarea_ways_DHDN.shp");
	file parking_shapefile <- file(file_input +  "investigationarea_parking_DHDN.shp");
	file pois_shapefile <- file(file_input + "investigationarea_pois_DHDN.shp");
	file countarea_shapefile <- file(file_input + "investigationarea_ca_DHDN.shp");
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
	int touringcompanys_symbol_size <- 100;
	
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
		// create the ways with all needed shapefile attributes
		create ways from: ways_shapefile with: [
				shape_objectid::int(read('OBJECTID'))							// OBJECTID (from ArcGIS)
			] {
				// change the ways name to somewhat useful
				name <- "ID-" + string(shape_objectid);
		}

		// create the weighted ways-graph to bind the touringcompanies on
		// and take the right ways-list as as basis, use the Djikstra algorithm
		// shape.perimeter is the normal factor = 1 weight! (make ist faster / slower)
		weights_map <- ways as_map (each:: each.shape.perimeter); 
		ways_graph <- as_edge_graph (ways) with_weights weights_map with_optimizer_type 'Djikstra' use_cache true;

		// create the parking-areas with all needed shapefile attributes
		create parking from: parking_shapefile with: [
				shape_objectid::int(read('OBJECTID')),		// OBJECTID (from ArcGIS)
				shape_attraction::string(read('Attrakt'))		// attraction of parking-area (how well-known is this parking-area?)
			] {
				// change the parking-areas name to somewhat useful
				name <- "ID-" + string(shape_objectid);
		}

		// create the POIs with all needed shapefile attributes
		create pois from: pois_shapefile with: [
				shape_objectid::int(read('OBJECTID')),		// OBJECTID (from ArcGIS)
				shape_attraction::string(read('Attrakt'))		// attraction of POI (how important is this POI?)
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_objectid);
		}


		create countarea from: countarea_shapefile with: [
				shape_objectid::int(read('OBJECTID'))		// OBJECTID (from ArcGIS)
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_objectid);
		}


		create touringcompanys number: number_of_touringcompanys {
			// get and set the starting point ("home") of the touringcompany
			list<parking> possibleparkingareas <- (parking) ;
			touringcompanys_home <- one_of(parking);

			// number of members per touringcompany
			touringcompanys_members <- get_random_value_of_weighted_list (touringcompanys_members_weighted_list);

			// set additional values and parameters for the touring company
			touringcompanys_status <- 'setup';
			location <- touringcompanys_home;
			speed <- truncated_gauss({touringcompanys_speed,touringcompanys_speed_sdev});
			
			// get a well written ID (only digits) from the automatically created one
			touringcompanys_id <- copy_between(name,15,999);

			// count touringcompanys at their homes = parking-areas
			ask parking(touringcompanys_home) {
				count_touringcompanys_home <- count_touringcompanys_home + 1; 
				count_touringcompanys_members_home <- count_touringcompanys_members_home + myself.touringcompanys_members; 
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


species ways  {
	// attributes from the shapefile
	int shape_objectid;						// OBJECTID (from ArcGIS)

	// statistical values
	float tc_on_way <- 0 update: 0;
	float sum_tc_on_way <- 0;
	float avg_tc_on_way <- 0;
	float max_tc_on_way <- 0;

	// base aspect
	aspect base {

		draw (shape + ways_symbol_size) color:ways_color;

	}
}


species parking  {
	// attributes from the shapefile
	int shape_objectid; 
	int shape_attraction;

	// variables and attributes
	int count_touringcompanys_home <- nil;
	int count_touringcompanys_members_home <- nil;
	
	// base aspect
	aspect base {
		draw geometry:square(parking_symbol_size) color:parking_color;
		if show_parking_id {
		}
	}
}


species pois  {
	// attributes from the shapefile
	int shape_objectid;	// OBJECTID (from ArcGIS) 
	int shape_attraction;	// attraction of POI (how important is this POI?) 

	// variables and attributes
	int count_touringcompanys_at_target <- nil;
	int count_touringcompanys_members_at_target <- nil;
	
	// base aspect
	aspect base {
		draw geometry:triangle(pois_symbol_size) color:pois_color;
	}
}


species countarea  {
	// attributes from the shapefile
	int shape_objectid;	// OBJECTID (from ArcGIS) 

	reflex count {
			list<touringcompanys>count_tc <- touringcompanys inside(self);
			write string(shape_objectid) + " --> "+ length(count_tc)+" = " + count_tc;
	}

	// base aspect
	aspect base {
		draw (shape) color:#aquamarine;
		draw string(shape_objectid) color: #black size: 4 at:point(self.location.x,self.location.y);
	}
}




species touringcompanys skills:[moving] {
	int touringcompanys_members <- nil;
	point touringcompanys_target <- nil;
    agent touringcompanys_target_agent <- nil;
	point touringcompanys_home <- nil;
	float distance_to_target_aerial <- nil;
	float distance_to_target_on_graph <- nil;
    path shortest_path <- nil;
	string touringcompanys_status <- nil;
    float hiked_distance <- nil;
    string touringcompanys_id <- nil; 

	reflex move_touringcompany {
		
		// (1) set first target and set the starting point ("home")
		if (touringcompanys_status = 'setup') {
//			list<pois> possibletargetpois <- (pois at_distance maximum_range_touringcompany) using topology(ways_graph);
//			list<pois> possibletargetpois <- (pois at_distance maximum_range_touringcompany);
//			list<int> pois_weighted_list <- possibletargetpois collect each.shape_attraction;
//			int random_weighted_poi <- one_of(pois at_distance maximum_range_touringcompany);
			
			touringcompanys_target_agent <- one_of(pois at_distance maximum_range_touringcompany);
			touringcompanys_target <- touringcompanys_target_agent;
			touringcompanys_status <- 'hikingtarget';
		}

		// (2) set new target for touringcompany to get back home,
		// after they rested for 1 cycle at the target (thats why this is BEFORE (3)!)
		if (touringcompanys_status = 'target') {
			touringcompanys_target <- touringcompanys_home;
			touringcompanys_status <- 'hikinghome';
		}

		// (3) touringcompany reached the POI target
		if (touringcompanys_status = 'hikingtarget' and touringcompanys_target = location and location != touringcompanys_home) {
			touringcompanys_target <- nil ;
			touringcompanys_status <- 'target';

			// count this touringcompany and its members at this target
			ask pois(touringcompanys_target_agent) {
				count_touringcompanys_at_target <- count_touringcompanys_at_target + 1; 
				count_touringcompanys_members_at_target <- count_touringcompanys_members_at_target + myself.touringcompanys_members; 
			}
		}
		
		// (4) touringcompany reached its home (target) as a final position
		if (touringcompanys_status = 'hikinghome' and touringcompanys_target = location and location = touringcompanys_home) {
			touringcompanys_target <- nil ;
			touringcompanys_status <- 'home';
		}

		// move it to the target
		path path_followed <- goto (target: touringcompanys_target, on: ways_graph, recompute_path:false, speed:speed, return_path: true);

		// calculate infos for distances and shortestpath
		if (touringcompanys_target != nil) {
			distance_to_target_aerial <- location distance_to touringcompanys_target;
			distance_to_target_on_graph <- location distance_to touringcompanys_target using topology(ways_graph);
			shortest_path <- path_between (ways_graph,location,touringcompanys_target);
		} else {
			distance_to_target_aerial <- nil;
			distance_to_target_on_graph <- nil;
			shortest_path <- nil;
		}	

		// calculate the hiked distance
		if (path_followed.shape != nil ) {
			hiked_distance <- hiked_distance + path_followed.shape.perimeter;
		}





		loop linesegments over: path_followed.segments {
				ask ways(path_followed agent_from_geometry linesegments) { 
					tc_on_way <- tc_on_way + 1 * (linesegments.perimeter / path_followed.shape.perimeter);
					sum_tc_on_way <- sum_tc_on_way + 1 * (linesegments.perimeter / path_followed.shape.perimeter);
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


experiment countareas  type: gui {
	float minimum_cycle_duration <- minimum_cycle_duration;
	user_command "ways" action:summarize_ways;
	user_command "SAVE" action:save_summarys;

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
				species countarea aspect: base refresh: true;
				species parking aspect: base refresh: true;
				species pois aspect: base refresh: true;
				species ways aspect: base refresh: true;
				species touringcompanys aspect: base refresh: true;
			}
	}

	action summarize_ways {
		loop i from: 0 to: (length(ways)-1) {
			write "i=" + string(i) + " --> objectid=" + ways[i].shape_objectid + ", name=" + ways[i].name + ", TConway=" + ways[i].tc_on_way;
		}
	}
	
	action save_summarys {
		// save shapefile summary of WAYS at the end 
		save (ways) to:"ways-summary-end.shp" rewrite:true type:"shp";

		// save textfile summary of WAYS at the end
		ask ways {
			save (
				"cycle: "+ cycle + "; shape_objectid: " + shape_objectid
				+ "; tc_on_way: " + int(tc_on_way*100000)/100000
				+ "; sum_tc_on_way: " + int(sum_tc_on_way*100000)/100000
				+ "; avg_tc_on_way: " + int(avg_tc_on_way*100000)/100000
				+ "; max_tc_on_way: " + int(max_tc_on_way*100000)/100000
				)
		   		to: "ways-summary-end.txt" rewrite: false type: "text";
		}
	}

}
