/**
* Name: flocking
* Author: Gudrun WALLENTIN, Dept. of Geoinformatics - Z_GIS, University of Salzburg
* Description: Reynold's boids model tranfserred to GAMA according to the algorithm used in NetLogo; updated for GAMA version 2025-6 
* Tags: boids model, flocking model
*/

model flocking

//if torus is set to "true", boids are in an endless, wrapped world (leaving boids appear on the other side)
global torus: false {

	//  parameters
	int number_of_boids <- 25 min: 3 max: 60; 	
	float min_separation <- 3.0  min: 0.1  max: 10.0 ;
	int max_separate_turn <- 5 min: 0 max: 20;
	int max_cohere_turn <- 5 min: 0 max: 20;
	int max_align_turn <- 8 min: 0 max: 20;
	float vision <- 30.0  min: 0.0  max: 70.0 ;	
			
	// initialise model
	init {
		// create and distribute boids
		create boids number:number_of_boids;
	}		
} 
	

// declare agents, cells and their behaviour
	//  boid agents
	species boids skills: [ moving ] {
		// boid attributes
		float size <- speed;
		rgb colour <- #black;
		point my_destination ;
	
		// flocking variables
	    list<boids> flockmates ; 	    
	    boids nearest_neighbour;	
	    float avg_head;
	    float avg_twds_mates ;
		
		// flocking movement
		reflex flock {
    		// in case all flocking parameters are zero wander randomly  	
			if (max_separate_turn = 0 and max_cohere_turn = 0 and max_align_turn = 0 ) {
				do wander amplitude: 120.0;
			}
			// otherwise compute the heading for the next timestep in accordance to my flockmates
			else {
				// search for flockmates
				do find_flockmates ;
				// turn my heading to flock, if there are other agents in vision 
				if (not empty (flockmates)) {
					do find_nearest_neighbour;
					if (distance_to (self, nearest_neighbour) < min_separation) {
						do separate;
					}
					else {
						do align;
						do cohere;
					}
					// move forward in the new direction
					do move;
				}
				// wander randomly, if there are no other agents in vision
				else {
					do wander amplitude: 120.0;
				}
			}			
	    }
		
		//flockmates are defined spatially, within a buffer of vision
		action find_flockmates {
	        flockmates <- ((boids overlapping (circle(vision))) - self);
		}
		
		//find nearest neighbour
		action find_nearest_neighbour {
	        nearest_neighbour <- flockmates with_min_of(distance_to (self.location, each.location)); 
		}		
		
	    // separate from the nearest neighbour of flockmates
	    action separate  {
	    	do turn_away (nearest_neighbour towards self, max_separate_turn);
	    }
	
	    //Reflex to align the boid with the other boids in the range
	    action align  {
	    	avg_head <- avg_mate_heading () ;
	        do turn_towards (avg_head, max_align_turn);
	    }
	
	    //Reflex to apply the cohesion of the boids group in the range of the agent
	    action cohere  {
			avg_twds_mates <- avg_heading_towards_mates ();
			do turn_towards (avg_twds_mates, max_cohere_turn); 
	    }
	    
	    //compute the mean vector of headings of my flockmates
	    float avg_mate_heading {
	    	ask flockmates {
	    		my_destination <- {location.x + cos(heading), location.y + sin(heading)};
	    	}
    		list<boids> flockmates_insideShape <- flockmates where (each.my_destination != nil);
    		float x_component <- sum (flockmates_insideShape collect (each.my_destination.x - each.location.x));
    		float y_component <- sum (flockmates_insideShape collect (each.my_destination.y - each.location.y));
    		//if the flockmates vector is null, return my own, current heading
    		if (x_component = 0 and y_component = 0) {
    			return heading;
    		}
    		//else compute average heading of vector  		
    		else {
    			// note: 0-heading direction in GAMA is east instead of north! -> thus +90
    			return -1 * atan2 (x_component, y_component) + 90;
    		}	
	    }  

	    //compute the mean direction from me towards flockmates	    
	    float avg_heading_towards_mates {
	    	float x_component <- mean (flockmates collect (cos (towards(self.location, each.location))));
	    	float y_component <- mean (flockmates collect (sin (towards(self.location, each.location))));
	    	//if the flockmates vector is null, return my own, current heading
	    	if (x_component = 0 and y_component = 0) {
	    		return heading;
	    	}
    		//else compute average direction towards flockmates
	    	else {
	    		// note: 0-heading direction in GAMA is east instead of north! -> thus +90
	    		return -1 * atan2 (x_component, y_component) + 90;	
	    	}
	    } 	    
	    
	    // cohere
	    action turn_towards (float new_heading, int max_turn) {
			float subtract_headings <- new_heading - heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((subtract_headings), max_turn);
	    }

		// separate
	    action turn_away (float new_heading, int max_turn) {
			float subtract_headings <- heading - new_heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((-1 * subtract_headings), max_turn);
	    }
	    
	    // align
	    action turn_at_most (float turn, int max_turn) {
	    	if abs (turn) > max_turn {
	    		if turn > 0 {
	    			//right turn
	    			heading <- heading + max_turn;
	    		}
	    		else {
	    			//left turn
	    			heading <- heading - max_turn;
	    		}
	    	}
	    	else {
	    		heading <- heading + turn;
	    	} 
	    }
	    
	    // boids visualisation settings
	
		// default arrow
		aspect arrow {
     		draw line([location, {location.x + cos(heading), location.y + sin(heading)}]) end_arrow: speed color: #black;
		}		
		
		// additional vision buffer 
		aspect buffer {
     		draw location + circle (vision) color: #green ;
		}
	}
  

// simulation settings
experiment simulation type:gui {
	
	//user defined parameters
	parameter 'iniatial number of animals' var: number_of_boids;
	parameter 'Max cohesion turn' var: max_cohere_turn ;
	parameter 'Max alignment turn' var:  max_align_turn; 
	parameter 'Max separation turn' var: max_separate_turn;
	parameter 'Minimal Distance'  var: min_separation;
	parameter 'Vision' var: vision;
	 
	output {	
		// map
		display map  {	
			//to visualise the vision buffer. Can be added optionally
			//species boids aspect: buffer transparency:0.9;
			species boids aspect: arrow;
		}
	}
}
