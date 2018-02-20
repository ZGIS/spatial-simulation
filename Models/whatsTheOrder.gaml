/**
* Model:		whatsTheOrder
* Author:		Stefan Mohr
* Description:	Determine the execution order in GAMA
*/

model whatsTheOrder

global {

	init {
		write "(1) init";
		create SpeciesA number: 1;
		create SpeciesB number: 1;
	}

	reflex check_stop_conditions {
		write "---> cycle: " + cycle; 

		// check pause / stop conditions
		if (cycle = 3) {
				do pause;
		}
	}

	reflex global_reflexA {
		write "(2) global_reflexA";
	}
	
	reflex global_reflexB {
		write "(3) global_reflexB";
	}

}


species SpeciesA {

	reflex SpeciesA_reflexA {
		write "(4) SpeciesA_reflexA";
	}
	
	reflex SpeciesA_reflexB {
		write "(5) SpeciesA_reflexB";
	}

	aspect SpeciesA_aspectA {
		write "(8) SpeciesA_aspectA";
	}

}


species SpeciesB {

	reflex SpeciesB_reflexA {
		write "(6) SpeciesB_reflexA";
	}
	
	reflex SpeciesB_reflexB {
		write "(7) SpeciesB_reflexB";
	}

	aspect SpeciesB_aspectA {
		write "(9) SpeciesB_aspectA";
	}

}


experiment whatsTheOrder type: gui {
	output {
		display name:"dummy" refresh:every(1 #cycles) type:opengl {
			species SpeciesA aspect:SpeciesA_aspectA refresh:true;
			species SpeciesB aspect:SpeciesB_aspectA refresh:true;
		}
	}
}
