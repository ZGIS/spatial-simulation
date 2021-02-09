/**
* Name: flocking
* Author: Gudrun WALLENTIN, Dept. of Geoinformatics - Z_GIS, University of Salzburg
* Description: Reynold's boids model tranfserred to GAMA according to the algorithm used in NetLogo 
* Tags: boids model, flocking model
*/

model flocking

global torus: false {

	//  parameters
	int number_of_fish <- 25 min: 3 max: 60; 	
	float min_separation <- 3.0  min: 0.1  max: 10.0 ;
	int max_separate_turn <- 5 min: 0 max: 20;
	int max_cohere_turn <- 5 min: 0 max: 20;
	int max_align_turn <- 8 min: 0 max: 20;
	float vision <- 30.0  min: 0.0  max: 70.0 ;	
			
	// initialise model
	init {
		// create and distribute fish
		create fish number:number_of_fish;
	}		
} 
	

// declare agents, cells and their behaviour
	//  fish agents
	species fish skills: [ moving ] {
		// fish attributes
		float size <- 2.0;
		rgb colour <- #black;
	
		// flocking variables
	    list<fish> flockmates ; 	    
	    fish nearest_neighbour;	
	    int avg_head;
	    int avg_twds_mates ;
		
		// flocking movement
		reflex flock {
    		// in case all flocking parameters are zero wander randomly  	
			if (max_separate_turn = 0 and max_cohere_turn = 0 and max_align_turn = 0 ) {
				do wander amplitude: 120;
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
					do wander amplitude: 120;
				}
			}			
	    }
		
		//flockmates are defined spatially, within a buffer of vision
		action find_flockmates {
	        flockmates <- ((fish overlapping (circle(vision))) - self);
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
	    int avg_mate_heading {
    		list<fish> flockmates_insideShape <- flockmates where (each.destination != nil);
    		float x_component <- sum (flockmates_insideShape collect (each.destination.x - each.location.x));
    		float y_component <- sum (flockmates_insideShape collect (each.destination.y - each.location.y));
    		//if the flockmates vector is null, return my own, current heading
    		if (x_component = 0 and y_component = 0) {
    			return heading;
    		}
    		//else compute average heading of vector  		
    		else {
    			// note: 0-heading direction in GAMA is east instead of north! -> thus +90
    			return int(-1 * atan2 (x_component, y_component) + 90);
    		}	
	    }  

	    //compute the mean direction from me towards flockmates	    
	    int avg_heading_towards_mates {
	    	float x_component <- mean (flockmates collect (cos (towards(self.location, each.location))));
	    	float y_component <- mean (flockmates collect (sin (towards(self.location, each.location))));
	    	//if the flockmates vector is null, return my own, current heading
	    	if (x_component = 0 and y_component = 0) {
	    		return heading;
	    	}
    		//else compute average direction towards flockmates
	    	else {
	    		// note: 0-heading direction in GAMA is east instead of north! -> thus +90
	    		return int(-1 * atan2 (x_component, y_component) + 90);	
	    	}
	    } 	    
	    
	    // cohere
	    action turn_towards (int new_heading, int max_turn) {
			int subtract_headings <- new_heading - heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((subtract_headings), max_turn);
	    }

		// separate
	    action turn_away (int new_heading, int max_turn) {
			int subtract_headings <- heading - new_heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((-1 * subtract_headings), max_turn);
	    }
	    
	    // align
	    action turn_at_most (int turn, int max_turn) {
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
	    
	    // fish visualisation settings
		// default arrow
		aspect arrow {
     		draw line([location, {location.x - size * cos(heading), location.y - size * sin(heading)}]) begin_arrow: 1 color: colour;
		}
	
		// alternative arrow
		aspect arrow2 {
			if (destination != nil) {
				draw line([location, destination]) end_arrow: 2 color: colour;
			}
		}
		
		// additional vision buffer 
		aspect buffer {
     		draw location + circle (vision) color: colour ;
		}
	}
  

// simulation settings
experiment simulation type:gui {
	
	//user defined parameters
	parameter 'iniatial number of animals' var: number_of_fish;
	parameter 'Max cohesion turn' var: max_cohere_turn ;
	parameter 'Max alignment turn' var:  max_align_turn; 
	parameter 'Max separation turn' var: max_separate_turn;
	parameter 'Minimal Distance'  var: min_separation;
	parameter 'Vision' var: vision;
	 
	output {	
		// map
		display map  {
			species fish aspect: arrow;	
			//species fish aspect: buffer transparency:0.8;
		}
	}
}
