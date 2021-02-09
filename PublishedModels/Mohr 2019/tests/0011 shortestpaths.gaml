model waysusage

global {

	// load the shape data for this world
	file bounds_shapefile <- file("../includes/TESTS/testarea_new_v1_bounds.shp");
	file ways_shapefile <- file("../includes/TESTS/testarea_new_v1_ways.shp");
	file parking_shapefile <- file("../includes/TESTS/testarea_new_v2_parking.shp");
	file pois_shapefile <- file("../includes/TESTS/testarea_new_v2_pois.shp");
	geometry shape <- envelope(bounds_shapefile);

	// set visual parameters
	rgb ways_color <- rgb(128, 128, 128,255);
	int ways_symbol_size <- 5;
	rgb parking_color <- rgb (0, 128, 255,255);
	int parking_symbol_size <- 50;
	rgb pois_color <- rgb (255, 128, 255,255);
	int pois_symbol_size <- 50;
	
	// generate a global (network) graph
    graph ways_graph;
    
	init {
		// create the ways with all needed shapefile attributes
		create ways from: ways_shapefile with: [
				shape_objectid::int(read('OBJECTID'))
		];

		// create the weighted ways-graph to bind the touringcompanies on
		ways_graph <- as_edge_graph (ways) with_optimizer_type 'Djikstra' use_cache true;

		// create the parking-areas with all needed shapefile attributes
		create parking from: parking_shapefile with: [
				shape_objectid::int(read('OBJECTID'))
		];

		// create the POIs with all needed shapefile attributes
		create pois from: pois_shapefile with: [
				shape_objectid::int(read('OBJECTID'))
		];

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		// calculate all the shortest paths
		loop src over:parking {
			loop dst over:pois {
				path shortest_path <- path_between (ways_graph,src,dst);
				int aerial_distance <- src distance_to dst;
				int path_distance <- src distance_to dst using topology(ways_graph);
				
				write string(src.name) + "-->" + string(dst.name) + ": "  + string(aerial_distance) + " ; " + string(path_distance) + " ; " + shortest_path;
				
			}
		}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	}
}


species ways  {
	// attributes from the shapefile
	int shape_objectid;

	// base aspect
	aspect base {
		draw (shape + ways_symbol_size) color:ways_color;
		draw string(name) color: #red;
	}
}


species parking  {
	// attributes from the shapefile
	int shape_objectid; 

	// base aspect
	aspect base {
		draw geometry:square(parking_symbol_size) color:parking_color;
		draw string(name) color: #black size: 10 at:point(self.location.x+30,self.location.y-60);
	}
}


species pois  {
	// attributes from the shapefile
	int shape_objectid;	// OBJECTID (from ArcGIS) 

	// base aspect
	aspect base {
		draw geometry:triangle(pois_symbol_size) color:pois_color;
		draw string(name) color: #black size: 4 at:point(self.location.x+30,self.location.y+80);
	}
}


experiment waysusage type: gui {
	output {
		display "Map Simulation" refresh:every(1) type:opengl {
				species parking aspect: base refresh: true;
				species pois aspect: base refresh: true;
				species ways aspect: base refresh: true;
			}
	}
}
