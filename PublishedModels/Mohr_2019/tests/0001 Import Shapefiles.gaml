model SimpleTest_for_shapefiles

global {

	file shapefile <- file("../includes/NLP_Harz/investigationarea_pois_DHDN.shp");
	geometry shape <- envelope(envelope(shapefile));

	init {

		// create the POIs with all needed shapefile attributes
		create shapedata from: shapefile with: [
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

		loop i from: 0 to: (length(shapedata)-1) {
			write "i=" + string(i) + " --> " + shapedata[i].name;
		}


	}
}


species shapedata {

	int shape_objectid;
	int shape_id;
	string shape_type;
	string shape_name;
	int shape_attraction;

	aspect base {
		draw geometry:square(50) color:#red;
	}	
}

experiment SimpleTest_for_shapefiles type: gui {
	output {
		display "Map Simulation" refresh:every(1) type:opengl {
			species shapedata aspect: base ;
		}
	}
}
