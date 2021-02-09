model NLP_Harz_Simulation

/* ========================================================================================================
* Project:			UNIGIS MSc 2015, Masterthesis 
* Description:	Agent-based model for the socio-economic monitoring of visitor streams.
*								A study using the example of the Harz National Park, Germany
* Author:				Stefan Mohr
* Version:			1.05
* Date:					2017-12-30
* Status:				FINAL VERSION (RC7 corrected and commented production version)
* =========================================================================================================
*/ 

// =========================================================================================================
// G L O B A L - Section
// =========================================================================================================

global {

	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// special parameters (runtime mode, machine times, special variables)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	// save the very first time this program was startet and if this should be written to the console
	float t0 <- machine_time;																		// machine_time at the start of the program 
	float t1;																										// machine_time at the start of a procedure etc. (used for incremenets)
	float t2 <- machine_time;																		// machine_time at the start of the last day
	float t3 <- machine_time;																		// machine_time at the start of a new day (to calculate the execution time of a day)
	bool write_core_message <- false;														// write machine_time outputs to the command line?

	// generate the actual datetimestring for filenames
	string actualdatetimestring <- string(date("now"),"yyMMdd-HHmmss_"); 

	// identification of the actual model purpose
	string identification <- "STANDARD_2011"; 

	// Bugfixing and special operations runtime-modes
	bool BUGFIXMODE <- false;																		// run the model in BUGFIXING mode
	bool FIXEDQUANTITIES <- false;															// run the model with no stochasticity for the tc-quantities
	bool EQUALATTRACTIONSMODE <- false;													// run the model with equal attractions
	bool EQUALWEIGHTS <- false;																	// run the model with equal weights for all ways
	bool DRYRUNMODE <- false;																		// run the model with all starting numbers set to 0 (dryrun)
	bool ACTIVATEWINTER <- false;																// run the model in winter-period-mode
	bool ACTIVATESUMMER <- false;																// run the model in summer-period-mode (summer wins over winter if both are TRUE)

	// special programmodus for sensitivity analysis
	bool ACTIVITYWINTERDAYS <- false;														// run the model in winter-period-mode for several days
	int numberofwinterdays <- 0;																// number of days with winter-mode


	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// fixed model parameters (which should NOT be changed)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	// fixed model parameters and variables for time-handling
	float step <- 300 #s;																				// simulation timestep in seconds, 300
	int date_cycles_per_simulation_day <- 144;									// 07:00 - 19:00 equals 144 steps à 5min
	int date_cycles_per_simulation_hour <- 12;									// 1 hour has 12 cycles à 5min
	int date_days <- 0;																					// calculated number of days
	int date_hours <- 7;																				// calculated number of hours
	int date_minutes <- 0;																			// calculated number of minutes

	// general simulation parameters (GUI etc.)
	int refresh_map_every <- 1;																	// ###NONE update map every X cycles, standard = 1
	int refresh_monitor_every <- 1;															// ###NONE update map every X cycles, standard = 1
	int refresh_chart_every <- 1;																// ###NONE update map every X cycles, standard = 1

	// directorys
	string file_input <- "../include/";													// ###NONE directory for input-data
	string file_output <- "../output/";													// ###NONE directory for outputs

	// load the shape data for this world
	file bounds_shapefile <- file(file_input + "bounds_DHDN.shp");								// bounding box
	file ways_shapefile <- file(file_input + "ways_DHDN.shp");										// ways
	file parking_shapefile <- file(file_input +  "parking_DHDN.shp");							// parking areas
	file bus_shapefile <- file(file_input + "bus_DHDN.shp");											// bus-stops
	file towns_shapefile <- file(file_input + "towns_DHDN.shp");									// towns
	file train_shapefile <- file(file_input + "train_DHDN.shp");									// train stations
	file pois_shapefile <- file(file_input + "pois_DHDN.shp");										// POIs
	file ca_shapefile <- file(file_input + "ca_DHDN.shp");												// counting areas
	file cp_shapefile <- file(file_input + "cp_DHDN.shp");												// counting points
	file railway_shapefile <- file(file_input + "railway_DHDN.shp");							// railway tracks
	file street_shapefile <- file(file_input + "streets_DHDN.shp");								// main streets
	file nlp_shapefile <- file(file_input + "nlp_DHDN.shp");											// Harz National Park perimeter
	file heatmap_shapefile <- file(file_input + "heatmap500_DHDN.shp");						// 500m fishnet for the heatmap
	file countcomplete_shapefile <- file(file_input + "countcomplete_DHDN.shp");	// complete study area

	// CSV-file with infos for a whole year and set (manually) the headings, store it in a matrix (YEARS_INFOS)
	file year_csv_file <- csv_file(file_input + "NLP_Harz_year1.csv",";");


	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// model parameters (which could be changed)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	// pausing, starting- and ending-condition for the simulation (normally all set to one year)
	int start_simuation_at_day <- 0;														// what is the first day (0..364) the simulation should start?
	string pause_condition <- 'oneyear'													// pause the model if a special condition is reached
		among:["allathome","endless","endafterdays","oneyear"];		//
	string simulation_year <- '2011'														// which type of year to simulate? Start (2011) or end of the ways-planning period (2020) 
		among:["2011","2020"];																		// 

	float modeling_reduction_factor <- 10.0; 										// reduction factor for all suitable values to gain computation speed
	int standard_number_of_tc_parking <- 442;										// standard number (unchanged, no influences etc.) of tc starting at P (and hiking)
	int standard_number_of_tc_parking_stopover <- 80;						// standard number (unchanged, no influences etc.) of tc starting at P (and doing a stopover)
	int standard_number_of_tc_bus <- 57;												// standard number (unchanged, no influences etc.) of tc starting at BUS
	int standard_number_of_tc_train <- 207;											// standard number (unchanged, no influences etc.) of tc starting at TRAIN
	int standard_number_of_tc_town <- 31;												// standard number (unchanged, no influences etc.) of tc starting at TOWN
	float calc_number_of_tc_halfrange_factor <- 0.33333;				// factor for definining the halfrange of the calc numbers (of the totals) 

	float tc_standard_speed <- 1.00 #m/#s;											// standard hikingspeed of tc 
	float tc_standard_speed_halfrange <- 0.50 #m/#s;						// halfrange for standard hikingspeed of tc 
	float tc_standard_hiking_distance <- 18000.0 #m;						// standard hiking_distance of tc 
	float tc_standard_hiking_distance_halfrange <- 14000.0 #m;	// halfrange for standard hiking_distance of tc
	float tc_standard_hiking_distance_localized <- 1800 #m;			// standard hiking distance for localized POIs (e.g. at the Brocken)
	float tc_standard_hiking_distance_stopover <- 1000 #m;			// standard hiking distance for TC that are doing a stopover
	float nearbyparking_path_distance <- 3000.0 #m;							// maximum distance on the path of a nearby-marked POI  

	float proba_tc_by_train_getback <- 0.75;										// probability (percent) of tc using trains to get back by train

	int tc_restingattarget_cycles_mean <- 3;										// mean of cycles a tc will rest at the target
	int tc_restingattarget_cycles_halfrange <- 2;								// halfrange of cycles a tc will rest at the target

	list<int> tc_members_weighted_list													// 1...10 members
			<- [14,56,11,9,3,2,2,1,1,1];														//
	list<int> tc_destinationtype_weighted_list									// weighted list for the different tc destination types
			<- [80,15,5];																						//
	list<string> tc_destinationtype_list												// the names of the different tc destination types (DO NOT CHANGE THESE VALUES)
			<- ["target","nature","hwn"];														//

	string shortest_path_algorithm <- "Dijkstra"								// routing algorithm for shortest path calculation 
		among: ["A*", "Dijkstra"];																// 

	float proba_winter_period <- 0.11;													// pobability of starting a winter-period
	int winter_period_mean <- 3;																// average (mean) duration of a winter period (in days)
	int winter_period_halfrange <- 2;														// halfrange for calculating a duration of a winter-period

	int tc_max_additional_targets <- 3;													// number of additional (secondary) targets a tc might go to 
	int tc_max_targets_atonce <- 2;															// number of known targets to a tc at the same time
	bool goto_additional_targets <- true;												// goto additional (secondary) targets
	float tc_probability_to_add_additional_targets <- 0.30;			// probability of a tc to hike to a secondary target   
	float max_additional_poi_aerial_distance <- 500.0;					// aerial distance secondary targets might have

	float usage_percent_category_lower <- 0.20;									// lower value for categorizing close to nature ways weights
	float usage_percent_category_upper <- 0.60;									// upper value for categorizing close to nature ways weights

	list<int> weather_factor_weighted_list <- [5,15,60,15,5];		// 5 different weather types (very good, good, moderate, bad, very bad)
	list<float> weather_factors_list														// the factors for the 5 different weather types
			<- [1.330,1.650,1.000,0.835,0.670];											//
	float factor_weather_smoothing_value <- 0.60;								// factor for smoothing the influence of the random weather factor
	float weather_factor_condition_good <- 1.1650;							// good weather conditions (decrease the hiking speed)
	float weather_factor_condition_bad <- 0.8350;								// bad weather condition (increase the hiking speed) 
	float weather_hikingspeed_factor_good <- 0.94444;						// hikingspeed factor for good weather
	float weather_hikingspeed_factor_normal <- 1.00;						// hikingspeed factor for bad weather
	float weather_hikingspeed_factor_bad <- 1.05556;						// hikingspeed factor for normal weather

	float way_difficulty_factor_winter_good <- 1.20;						// weight-factor for non winter-hiking-ways
	float way_difficulty_factor_winter_bad <- 1.80;							// weight-factor for winter-hiking-ways

	float factor_weekday_value <- 1.20;													// factor for weekends over weeksdays
	float factor_holiday_value <- 3.00;													// factor for (bank) holidays

	bool save_periodical_files <- true;													// output of periodical values to CSV and TXT files
	bool use_actualdatetimestring <- true;											// preceed the exported filenames by the acual actualdatetimestring
	bool save_parameter_summary <- true;												// write a file with a summary of all parameters for this model
	bool save_values_summary <- true;														// write a file with a summary of all important values at the end of the simulation
	bool save_species_summarys <- true;													// write a shapefile for all species with the most important values

	bool show_linetotarget <- true;															// draw a line from the touringcompany to the target
	bool show_tc_id <- false;																		// show names at every touringcompany
	bool show_poi_id <- false;																	// show the IDs of the POIs
	bool show_parking_id <- false;															// show the IDs of the parking-areas
	bool show_bus_id <- false;																	// show the IDs of the bus-stops
	bool show_town_id <- false;																	// show the IDs of the towns
	bool show_counting_id <- false;															// show the IDs of ca and cp
	bool display_tc <-true;																			// show tc generally on the map
	bool display_inside_nlp <-true;															// show tc which were also inside the nlp area
	bool display_outside_nlp <-true;														// show tc which were only outside the nlp area

	string display_areas <- 'NONE'  														// select the counting-areas (ca) to display on the map
		among:["NONE","ALL","Revier","Bereich"];									//
	string display_tc_destinationtype <- 'ALL'									// select which destination types to display on the map
		among:["ALL","target","nature","hwn"];										//
	string display_tc_starttype <- 'ALL'												// select which tc starting-types to display on the map
		among:["ALL","parking","bus","town","train"];							//
	bool display_heatmap <- false;															// show the heatmap
	float colorizing_min_perc <- 0.10;													// minimum value for heatmap to display
	bool show_percentage_area <- false;													// show the percentage values at areas and heatmap 


	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// fixed parameter for GUI etc. (which could be changed)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	int label_offset <- 20;																			// xy-offset for labeling species

	rgb ways_color <- rgb(140,140,140,255);											// color for ways on the map
	int ways_symbol_size_unsed <- 4;														// symbol size for unused ways
	int ways_symbol_size_used <- 8;															// symbol size for unused ways

	rgb parking_color <- rgb(0,100,255,255);										// color for parking areas on the map
	int parking_symbol_size <- 70;															// symbol size for parking areas 

	rgb bus_color <- rgb(0,192,255,255);												// color for bust-stops on the map
	int bus_symbol_size <- 70;																	// symbol size for bus-stops

	rgb town_color <- rgb(128,0,64,255);												// color for towns on the map
	int town_symbol_size <- 70;																	// symbol size for towns

	rgb train_train_color <- rgb(64,64,64,255);									// color for train stations (and get back by train) on the map
	rgb train_valley_color <- rgb(128,0,255,255);								// color for train stations (and hike to the valley) on the map
	int train_symbol_size <- 70;																// symbol size for train stations

	rgb pois_color_primary <- rgb(255,128,255,255);							// color for primary POIs on the map
	rgb pois_color_secondary <- #darkgreen;											// color for secondary targets on the map
	int pois_symbol_size <- 70;																	// symbol size for POIs

	rgb cp_color <- #chocolate;																	// color for countingpoints on the map
	int cp_symbol_size <- 45;																		// symbol size for countingpoints

	rgb railway_color <- rgb(165,90,90,255);										// color for railways on the map
	int railway_symbol_size <- 8;																// symbol size for railways

	rgb street_color <- rgb(110,110,110,255);										// color for main streets on the map
	int street_symbol_size <- 10;																// symbol size for main streets

	rgb nlp_color <- rgb(140,170,140,255);											// color for NLP perimeter on the map
	int nlp_symbol_size <- 15;																	// symbol size for NLP perimeter

	rgb tc_color_setup <- rgb(255,157,157,255);									// color for tc which are in the setup phase
	rgb tc_color_nospace <- rgb(128,0,0,255);										// color for tc which have found no space left at a parking area
	rgb tc_color_notarget <- rgb(64,0,0,255);										// color for tc which have found no POI
	rgb tc_color_late <- #darkblue;															// color for tc which are not back home by 19:00 
	rgb tc_color_distancebudget <- #orange;											// color for tc which are abice their distancebudget 
	rgb tc_color_hikingtarget <- rgb(255,0,0,255);							// color for tc which are hiking to a POI
	rgb tc_color_target <- rgb(0,128,0,255);										// color for tc which are at a POI
	rgb tc_color_hikinghome <-rgb(249,192,0,255);								// color for tc which are hiking home
	rgb tc_color_home <- rgb(192,192,192,255);									// color for tc which are at home
	int tc_symbol_size <- 25;


	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// global variables and values for internal use (which should NOT be changed)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	int total_standard_number_of_tc															// total sum of all standard numbers of tc
			<- standard_number_of_tc_parking												//
			+ standard_number_of_tc_parking_stopover								//
			+ standard_number_of_tc_bus															//
			+ standard_number_of_tc_train														//
			+ standard_number_of_tc_town;														//

	string set_season_type <- '';																// combined set season-type
	float factor_weekday;																				// factor for calculating the number of touring companys, mo-fr = 1.0
	float factor_season;																				// factor for calculating the number of touring companys, season influence 
	float factor_holiday;																				// factor for calculating the number of touring companys, bank holiday?
	float weather_hikingspeed_today_factor;											// the hikingspeed is influenced by the weather
	int tc_startcycle_mean;																			// mean of the startcycle of all tc
	int tc_startcycle_halfrange;																// halfrange  of the startcycle of all tc
	int tc_lastlightcycle;																			// cycle with the last sunlight = sundown
	int tc_startcycle_mean_stopover;														// mean of the startcycle of all tc doing a stopover
	int tc_startcycle_halfrange_stopover;												// halfrange of the startcycle of all tc doing a stopover
	int possible_winter;																				// could there be winter with snow or is it summertime?
	int remaining_winter_days <- 0;															// how long will this winter-period still there?

	float calc_factor_weather;																	// caclulated weather factor for the number of touring companys
	float calc_factor_weather_lastcycle;												// caclulated weather factor of previous cycle for the number of touring companys
	float calc_factor_parking;																	// caclulated parking-sites factor for the number of touring companys
	float calc_factor_parking_stopover;													// caclulated parking-stopover factor for the number of touring companys
	float calc_factor_bus;																			// caclulated bus factor for the number of touring companys
	float calc_factor_town;																			// caclulated town factor for the number of touring companys
	float calc_factor_train;																		// caclulated train factor for the number of touring companys

	int calc_number_of_tc_parking;															// calculated number of touring companys starting at parking areas
	int calc_number_of_tc_parking_stopover; 										// calculated number of touring companys starting at parking areas, doing a stopover
	int calc_number_of_tc_bus;																	// calculated number of touring companys starting at bus-stops 
	int calc_number_of_tc_town;																	// calculated number of touring companys starting at towns
	int calc_number_of_tc_train;																// calculated number of touring companys starting at the train station at the Brocken

	string date_calculated;																			// self calculated date in a formatte dway
	string years_infos_date;																		// years_info calculated date and infos

	int pause_condition_value <- 1;															// universal value for several pause-conditions 			
	bool is_initial_pause <- false;															// idicates the initial pausing trigger

	geometry shape <- envelope(bounds_shapefile);								// get the complete shape geometry

	matrix year_infos <- matrix(year_csv_file);									// fill a matrix (array) with the values from the CSV file 
	string years_infos_infostring;															// combined info from the CSV-file to display in one string
	list<string> xaxis_oneyear;																	// label for graphs for one complete year
	bool write_cvs_headers_at_first_time <- true;								// set to true if this is the first cycle / run

	// global graphs, weights and lists of ways and POIs  
	graph ways_graph;																						// network graph with normal weights
	graph ways_graph_nature;																		// network graph with weights for close to nature hikers 

	map<ways,float> weights_map_summer;													// weights for the ways during summer period
	map<ways,float> weights_map_summer_nature;									// weights for the ways during summer period for nature-hiking tc
	map<ways,float> weights_map_winter;													// weights for the ways during winter period
	map<ways,float> weights_map_winter_nature;									// weights for the ways during winter period for nature-hiking tc
	map<ways,float> weights_map_summer_2020;										// weights for the ways during summer period
	map<ways,float> weights_map_summer_nature_2020;							// weights for the ways during summer period for nature-hiking tc
	map<ways,float> weights_map_winter_2020;										// weights for the ways during winter period
	map<ways,float> weights_map_winter_nature_2020;							// weights for the ways during winter period for nature-hiking tc

	list<ways> ways_summer;																			// usable ways for hiking during the summer
	list<ways> ways_winter;																			// usable ways for hiking during the winter
	list<ways> ways_summer_2020;																// usable ways for hiking during the summer at 2020
	list<ways> ways_winter_2020;																// usable ways for hiking during the winter at 2020

	list<pois> pois_all;																				// list of all target pois (for the set sseason_type)
	list<pois> pois_all_summer;																	// list of all target pois for the summer
	list<pois> pois_all_winter;																	// list of all target pois for the winter
	list<pois> pois_primary;																		// list of all primary target pois (for the set sseason_type)
	list<pois> pois_primary_summer;															// list of all primary target pois for the summer
	list<pois> pois_primary_winter;															// list of all primary target pois for the winter


	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// global state variables which carry some of the output-values
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	// total values / quantities
	int total_tc_parking <- 0;																	// sum of all tc starting at parking areas
	int total_tc_bus <- 0;																			// sum of all tc starting at bus-stops 
	int total_tc_town <- 0;																			// sum of all tc starting at towns
	int total_tc_train_train <- 0;															// sum of all tc starting at the Brocken (and returning by train)
	int total_tc_train_valley <- 0;															// sum of all tc starting at the Brocken (and hiking to the valley)
	int total_tc_nospace <- 0;																	// sum of all tc which found no parkingspace left
	int total_tc_notarget <- 0;																	// sum of all tc which found no target to go for
	int total_tc_late <- 0;																			// sum of all tc which are not back home by 19:00
	int total_tc_distancebudget <- 0;														// sum of all tc which are above their distance budget
	int total_tc_desttype_target <- 0;													// sum of all tc with type target
	int total_tc_desttype_nature <- 0;													// sum of all tc with type nature
	int total_tc_desttype_hwn <- 0;															// sum of all tc with type hwn (Harzer Wandernadel)

	int total_tc_mb_parking <- 0;																// sum of all tc-members starting at parking areas
	int total_tc_mb_bus <- 0;																		// sum of all tc-members starting at 
	int total_tc_mb_town <- 0;																	// sum of all tc-members starting at 
	int total_tc_mb_train_train <- 0;														// sum of all tc-members starting at 
	int total_tc_mb_train_valley <- 0;													// sum of all tc-members starting at 
	int total_tc_mb_nospace <- 0;																// sum of all tc-members tc which found no parkingspace left
	int total_tc_mb_notarget <- 0;															// sum of all tc-members which found no target to go for
	int total_tc_mb_late <- 0;																	// sum of all tc-members which are not back home by 19:00 
	int total_tc_mb_distancebudget <- 0;												// sum of all tc-members which are above their distance budget 
	int total_tc_mb_desttype_target <- 0;												// sum of all tc-members with type target 
	int total_tc_mb_desttype_nature <- 0;												// sum of all tc-members with type nature 
	int total_tc_mb_desttype_hwn <- 0;													// sum of all tc-members with type hwn (Harzer Wandernadel) 

	int total_winter_days <- 0;																	// sum of all winter-period days
	int total_additional_restaurant_added <- 0;									// sum of all additional restaurant adds
	int total_additional_poi_added <- 0;												// sum of all additional POIs add (incl. restaurants)
	int total_morethan2cp <- 0;																	// sum of all occurances of more than 2 CP found
	int total_nilpath <- 0;																			// sum of all nil path (no path) founds
	
	// total of totals
	int tc_total <- 0;																					// sum of all tc
	int tc_total_last <- 0;																			// sum of all tc last day
	int tc_total_nlp <- 0;																			// sum of all tc inside the NLP perimeter
	int tc_total_outside <- 0;																	// sum of all tc outside the NLP perimter (which have never been inside the NLP)
	int mb_total <- 0;																					// sum of all tc-members
	int mb_total_last <- 0;																			// sum of all tc-members last day
	int mb_total_nlp <- 0;																			// sum of all tc-members inside the NLP perimeter
	int mb_total_outside <- 0;																	// sum of all tc-members outside the NLP perimter (which have never been inside the NLP)

	// special counts for the BROCKEN
	int count_brocken_members_TOTAL <- 0;												// sum of tc-members which were at the Brocken
	float count_brocken_members_percent_BADHARZBURG <- 0.0;			// sum of tc-members which were at the Brocken and hike to BADHARZBURG 
	float count_brocken_members_percent_TORFHAUS <- 0.0;				// sum of tc-members which were at the Brocken and hike to TORFHAUS
	float count_brocken_members_percent_ODERBRUECK <- 0.0;			// sum of tc-members which were at the Brocken and hike to ODERBRÜCK
	float count_brocken_members_percent_BRAUNLAGE <- 0.0;				// sum of tc-members which were at the Brocken and hike to BRAUNLAGE
	float count_brocken_members_percent_SCHIERKE <- 0.0;				// sum of tc-members which were at the Brocken and hike to SCHIERKE
	float count_brocken_members_percent_DREIANNENHOHNE <- 0.0;	// sum of tc-members which were at the Brocken and hike to DREIANNENHOHNE
	float count_brocken_members_percent_ILSENBURG <- 0.0;				// sum of tc-members which were at the Brocken and hike to ILSENBURG

	// distributions
	map<string,list> distribution_tc_members <- distribution_of([0],1);									// distribution of the members of tc
	map<string,list> distribution_tc_max_hiking_distance <- distribution_of([0],1);			// distribution of the max_hinking_distances of tc
	map<string,list> distribution_tc_restingattarget_cycles <- distribution_of([0],1);	// distribution of the tc_restingattarget_cycles of tc
	map<string,list> distribution_tc_startcycle <- distribution_of([0],1);							// distribution of the tc_startcycle of tc

	// define some global lists (e.g. for generating statistical values)
	list<int> list_tc_members;																	// how much members has this touringcompany?
	list<float> list_tc_standard_speed;													// what is the speed of each touringcompany?
	list<float> list_tc_max_hiking_distance;										// the list of all max hiking distances
	list<string> list_tc_destinationtype;												// list of all different tc destination types of the tc
	list<int> list_tc_restingattarget_cycles;										// list of resting cycle numbers of all tc
	list<float> list_tc_hiked_distance;													// how much distance has every touringcompany hiked?
	list<int> list_tc_startcycle <-nil;													// list of all startcycles of all tc

	list<int> list_count_tc_members_hiked_area_1;								// how much members have hiked this area 'Revier' (counted several times)?
	list<int> list_count_tc_members_hiked_area_2;								// how much members have hiked this area 'Bereich' (counted several times)?
	list<int> list_count_tc_members_hiked_area_1_once;					// how much members have hiked this area 'Revier' (counted only once)?
	list<int> list_count_tc_members_hiked_area_2_once;					// how much members have hiked this area 'Bereich' (counted only once)?
	list<int> list_count_tc_members_hiked_way;									// how much members have hiked this way (counted only once)?
	list<int> list_count_tc_members_hiked_heatmap;							// how much members have hiked this heatmap area (counted only once)?

	list<float>	list_ways_usage_percent;												// list of all usages (percent) of the ways
	list<int>	list_ways_usage_percent_category;									// list of all categorized usages (percent) of the ways


	// ---------------------------------------------------------------------------------------
	// global: initialize the model
	// ---------------------------------------------------------------------------------------
	init {
		// Output of the the starttime and the actual machine_time core messages
		if (write_core_message = true) {write "~~~ t0=" + t0;}
		t1 <- machine_time;
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> top of init routine"; t1 <- machine_time;}

		// generate the labeling of the x-axis for most of the diagrams
		loop i from:0 to:370 {
			add string(i) to:xaxis_oneyear;
		}

		// create the ways with all needed shapefile attributes
		create ways from:ways_shapefile with:[
				shape_objectid::int(read('OBJECTID')),							// OBJECTID (from ArcGIS)
				shape_name::string(read('WEGENAME')),								// wayname
				shape_wayid::string(read('WEGENR')),								// way number
				shape_wayid_planning::int(read('IST_WEGEPL')),			// planning for 2020 for this way (1 = closing this way)
				shape_summer_hiking::int(read('THESIS_SUM')),				// summer hiking
				shape_winter_hiking::int(read('THESIS_WIN')),				// winter hiking
				shape_thesis_nomaxcount::int(read('THESIS_NMA')),		// this way should not count for the possible maximum use by tc (e.g. at the Brocken summit)
				shape_way_category::int(read('THESIS_KAT')),				// category of this way (small, broad, street, etc.) re-categorized for this simulation
				shape_way_nature::int(read('THESIS_NAT')),					// way which is nature oriented 
				shape_way_difficulty::int(read('THESIS_SCH'))				// difficulty level of this way (hard to go there?) 
			] {
				// change the ways name to somewhat useful
				name <- "ID-" + string(shape_objectid) + ": " + shape_wayid + "(" + shape_name + ")";

				// calculate the dificulty weights-factor for this way
				way_difficulty_factor_summer <- shape_way_difficulty / 100.0;
				if (shape_winter_hiking = 10) {
						way_difficulty_factor_winter <- way_difficulty_factor_winter_good;
					} else if (shape_winter_hiking = 20) {
						way_difficulty_factor_winter <- way_difficulty_factor_winter_bad;
					} else if (shape_winter_hiking = 0) {
						way_difficulty_factor_winter <- 999999.0;
				}
		}

		// list of ways for hiking during the summer and during the winter
		ways_summer <- ways where(each.shape_summer_hiking != 0);
		ways_winter <- ways where(each.shape_winter_hiking != 0);
		ways_summer_2020 <- ways where(each.shape_summer_hiking != 0 and each.shape_wayid_planning != 1);
		ways_winter_2020 <- ways where(each.shape_winter_hiking != 0 and each.shape_wayid_planning != 1);

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init ways";}

		// create the parking-areas with all needed shapefile attributes
		create parking from: parking_shapefile with:[
				shape_objectid::int(read('OBJECTID')),							// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),													// ID (primarykey)
				shape_city::string(read('Ort')),										// city where parking-area is
				shape_name::string(read('Name')),										// name
				shape_attraction::int(read('Attrakt')),							// attraction of parking-area (how well-known is this parking-area?)
				shape_attraction_stopover::int(read('Attrakt_so')),	// attraction of parking-area (how well-known is this parking-area?) for stopovers
				shape_attraction_train::int(read('Attrakt_tr')),		// attraction of parking-area for hiking back from a train station
				shape_capacity::int(read('STELLPLAET'))							// what's the capacity of this parking area?
			] {
				// change the parking-areas name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_city + " " + shape_name ;
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init parking"; t1 <- machine_time;}

		// create the bus-stops with all needed shapefile attributes
		create bus from: bus_shapefile with:[
				shape_objectid::int(read('OBJECTID')),						// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),												// ID (primarykey)
				shape_name::string(read('name')),									// name
				shape_attraction::int(read('Attrakt')),						// attraction of parking-area (how well-known is this parking-area?)
				shape_attraction_train::int(read('Attrakt_tr'))		// attraction of parking-area for hiking back from a train station
			] {
				// change the parking-areas name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_name ;
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init bus"; t1 <- machine_time;}

		// create the twons with all needed shapefile attributes
		create towns from: towns_shapefile with:[
				shape_objectid::int(read('OBJECTID')),					// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),											// ID (primarykey)
				shape_name::string(read('name')),								// name
				shape_attraction::int(read('Attrakt')),					// attraction of parking-area (how well-known is this parking-area?)
				shape_attraction_train::int(read('Attrakt_tr'))	// attraction of parking-area for hiking back from a train station
			] {
				// change the parking-areas name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_name ;
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init town"; t1 <- machine_time;}

		// create the trainstations with all needed shapefile attributes
		create train from: train_shapefile with:[
				shape_objectid::int(read('OBJECTID')),	// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),							// ID (primarykey)
				shape_name::string(read('name')),				// name
				shape_attraction::int(read('Attrakt'))	// attraction of train station (how well-known is this parking-area?)
			] {
				// change the parking-areas name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_name ;
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init train"; t1 <- machine_time;}

		// create the POIs with all needed shapefile attributes
		create pois from:pois_shapefile with:[
				shape_objectid::int(read('OBJECTID')),						// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),												// ID (primarykey)
				shape_type::string(read('Typ')),									// type
				shape_name::string(read('name')),									// name
				shape_attraction::int(read('Attrakt')),						// attraction of POI (how important is this POI?)
				shape_nearbyparking::int(read('PNAEHE')),					// is there a nearby P?
				shape_primary::int(read('PRIMAER')),							// is this a primary POI where people want to hike to?
				shape_summer::int(read('SUMMER')),								// is this POI reachable during the summer?
				shape_winter::int(read('WINTER')),								//  is this POI reachable during the winter?
				shape_attraction_add::int(read('Attrakt_ad')),		// attraction of POI as an additional POI / target 
				shape_add_probability::int(read('WAHRSCH_ad')),		// special probability to add this POI as an additional one
				shape_attraction_nature::int(read('THESIS_NAT'))	// attraction for close to nature hiker to go to this POI
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_type + " " + shape_name;
		}
		// lists of poi-types
		pois_all_summer <- pois where(each.shape_summer = 1);
		pois_all_winter <- pois where(each.shape_winter = 1);
		pois_primary_summer <- pois where(each.shape_primary = 1 and each.shape_summer = 1);
		pois_primary_winter <- pois where(each.shape_primary = 1 and each.shape_winter = 1);

		// invert the attraction for close to nature hiker because it was saved as weights (original: 10=good, 20=midium, 30=bad)
		int shape_attraction_nature_max <- max(pois collect(each.shape_attraction_nature));
		ask pois {
			shape_attraction_nature <- (shape_attraction_nature_max+10) - shape_attraction_nature;
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init POIs"; t1 <- machine_time;}

		// create the ca with all needed shapefile attributes
		create ca from:ca_shapefile with:[
				shape_objectid::int(read('OBJECTID')),	// OBJECTID (from ArcGIS)
				shape_id::int(read('ID')),							// ID (primarykey)
				shape_name::string(read('Name')),				// name
				shape_type::string(read('Typ'))					// type
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_name; 
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init ca"; t1 <- machine_time;}

		// create the countingpoits with all needed shapefile attributes
		create cp from: cp_shapefile with: [
				shape_objectid::int(read('OBJECTID')),	// OBJECTID (from ArcGIS)
				shape_id::int(read('id')),							// ID (primarykey)
				shape_name::string(read('Name')),				// name
				shape_cp::int(read('Countingpo')),			// cp (number)
				shape_subpoint::int(read('Subpoint')),	// subpoint (2 points per cp)
				shape_direction::int(read('Direction'))	// describing the direction
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_id) + ": " + shape_name; 
		}

		// create the mainstreets with all needed shapefile attributes
		create street from: street_shapefile with:[
				shape_objectid::int(read('OBJECTID'))		// OBJECTID (from ArcGIS)
			];

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init street"; t1 <- machine_time;}

		// create the railways with all needed shapefile attributes
		create railway from: railway_shapefile with:[
				shape_objectid::int(read('OBJECTID'))		// OBJECTID (from ArcGIS)
			];

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init railway"; t1 <- machine_time;}

		// create the railways with all needed shapefile attributes
		create nlp from: nlp_shapefile with:[
				shape_objectid::int(read('OBJECTID'))		// OBJECTID (from ArcGIS)
			];

		// create the heatmap with all needed shapefile attributes
		create heatmap from:heatmap_shapefile with:[
				shape_id::int(read('ID'))	// ID
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_id); 
		}

		// create the countcomplete with all needed shapefile attributes
		create countcomplete from:countcomplete_shapefile with:[
				shape_objectid::int(read('OBJECTID'))		// OBJECTID (from ArcGIS)
			] {
				// change the POI name to somewhat useful
				name <- "ID-" + string(shape_objectid); 
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init nlp"; t1 <- machine_time;}

		// do we have a special operations mode for winter-days?
		if (ACTIVITYWINTERDAYS) {
				remaining_winter_days <- numberofwinterdays + 1;
				total_winter_days <- 0;
				// now activate the ways for the simulation_year and start with "winter"-setting
				do activate_ways_and_pois (simulation_year, 'winter');
			} else {
				// now activate the ways for the simulation_year and start with "summer"-setting
				do activate_ways_and_pois (simulation_year, 'summer');
		}

		// set ALL ATTRACTIONS to an equal value for a normal and un-parametrized model (special operations mode)
		if (EQUALATTRACTIONSMODE) {
			ask parking {
				shape_attraction <- 10;
				shape_attraction_train <- 10;
			}
			ask bus {
				shape_attraction <- 10;
				shape_attraction_train <- 10;
			}
			ask towns {
				shape_attraction <- 10;
				shape_attraction_train <- 10;
			}
			ask train {
				shape_attraction <- 10;
			}
			ask pois {
				shape_attraction <- 10;
				shape_attraction_add <- 10;
				shape_add_probability <- -1;
			}
		}

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of setting equalactivities and equalquantites"; t1 <- machine_time;}

		// write a summary with all set parameters
		if (save_parameter_summary) { do save_summary_of_parameters; }

		// Output of the actual machine_time core messages
		if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end of init tc"; t1 <- machine_time;}

	}


	// ---------------------------------------------------------------------------------------
	// global: check the stop- and pausing-conditions 
	// --> one cycle behind screen!!!
	// ---------------------------------------------------------------------------------------
	reflex check_stop_conditions {
		// check pause / stop conditions
		if (pause_condition = 'allathome' and not is_initial_pause) {
			if (tc count(each.name != nil) = 0) {
				if (save_values_summary) { do save_summary_of_values_CSV; }				
				if (save_species_summarys) { do save_species_summarys; }				
				is_initial_pause <- true;
				do pause;
			}
		}
		if (pause_condition = 'endafterdays') {
			if (date_days = pause_condition_value and not is_initial_pause) {
				if (save_values_summary) { do save_summary_of_values_CSV; }				
				if (save_species_summarys) { do save_species_summarys; }				
				is_initial_pause <- true;
				do pause;
			}
		}
		if (pause_condition = 'oneyear') {
			if (date_days = 367 and not is_initial_pause) {
				if (save_values_summary) { do save_summary_of_values_CSV; }				
				if (save_species_summarys) { do save_species_summarys; }				
				is_initial_pause <- true;
				do pause;
			}
		}
	}


	// ---------------------------------------------------------------------------------------
	// global: calculate all global values at each timestep 
	// --> one cycle behind screen!!!
	// ---------------------------------------------------------------------------------------
	reflex calculate_global_values {

		// calculate hour and minutes, write the calculated date in a nice formatted way
		string hours;
		string minutes <-nil;

		if (cycle mod date_cycles_per_simulation_hour = 0 and cycle != 0) {
			// at 19:00 roll forward to 07:00 of the next day
			if (cycle mod date_cycles_per_simulation_day = 0 and cycle != 0) {
				date_days <- date_days + 1;
				// set t2 for execution time calculations
				t2 <- t3;
				t3 <- machine_time;
			}
		}

		date_hours <- div(mod(cycle,date_cycles_per_simulation_day),date_cycles_per_simulation_hour) + 7;
		date_minutes <- (	cycle
											- div(mod(cycle,date_cycles_per_simulation_day),date_cycles_per_simulation_hour)*date_cycles_per_simulation_hour
											- div(cycle,date_cycles_per_simulation_day)*date_cycles_per_simulation_day
										)*5;
		if (date_hours < 10) { hours <- "0" + date_hours;} else {	hours <- string(date_hours);}
		if (date_minutes < 10) {	minutes <- "0" + date_minutes;} else {minutes <- string(date_minutes);}

		// calculations for all years_infos
		date_calculated <- "day " + date_days + ", " + hours + ":" + minutes + " (" + year_infos[2,date_days] + " " + year_infos[1,date_days] +")"; 
		years_infos_infostring <-
			"[" + year_infos[0,date_days] + "] "	// day
			+ year_infos[1,date_days] + ", "			// date
			+ year_infos[2,date_days] + ", "			// weekday
			+ year_infos[3,date_days] + ", "			// seasonfactor
			+ year_infos[4,date_days] + ", "			// holiday
			+ year_infos[5,date_days] + ", "			// tc_startcycle_mean
			+ year_infos[6,date_days] + ", "			// tc_startcycle_halfrange
			+ year_infos[7,date_days] + ", "			// lastlight_cycle
			+ year_infos[8,date_days] + ", "			// tc_startcycle_mean_stopover
			+ year_infos[9,date_days] + ", "			// tc_startcycle_halfrange_stopover
			+ year_infos[10,date_days];						// possible_winter

		// at a new day (and also at the very first beginning) start the creation of the tc
		if (	cycle mod(date_cycles_per_simulation_hour) = 0
					and cycle mod(date_cycles_per_simulation_day) = 0
					and date_days >= start_simuation_at_day
			) {
			do start_a_new_day;
		}	
			
		// ****** COUNTCOMPLETE: calculations, operations, periodically file-outputs
		ask countcomplete {
			// statistical values
			list<tc>counted_tc <- tc inside(self);
			tc_in_countcomplete <- length(counted_tc); 
			sum_tc_in_countcomplete <- sum_tc_in_countcomplete + length(counted_tc);
			tc_members_in_countcomplete <- sum(counted_tc collect(each.tc_members));
			sum_tc_members_in_countcomplete <- sum_tc_members_in_countcomplete + sum(counted_tc collect(each.tc_members));

			// loop over all counted tc in this area
			loop t over: counted_tc {
				// simple count-statistics
				if (not(list_tc_hiked_countcomplete contains (string(int(t))))) {
						add string(int(t)) to:list_tc_hiked_countcomplete;
						count_tc_members_hiked_countcomplete <- count_tc_members_hiked_countcomplete + t.tc_members;
				}
				count_tc_hiked_countcomplete <- length(list_tc_hiked_countcomplete);
				ask t {
					was_inside_nlp <- true;
				}
			}

			// calculate total of totals values
			mb_total_last <- mb_total; 
			mb_total <- total_tc_mb_parking+total_tc_mb_bus+total_tc_mb_town+total_tc_mb_train_train+total_tc_mb_train_valley+total_tc_mb_nospace;
			mb_total_nlp <- count_tc_members_hiked_countcomplete;
			mb_total_outside <- mb_total_last-mb_total_nlp;
	
			tc_total_last <- tc_total;
			tc_total <- total_tc_parking+total_tc_bus+total_tc_town+total_tc_train_train+total_tc_train_valley+total_tc_nospace;
			tc_total_nlp <- count_tc_hiked_countcomplete;
			tc_total_outside <- tc_total_last-tc_total_nlp;
		}

		// ***** WAYS: calculations, operations, periodically file-outputs
		ask ways {
			// statistical values
			if cycle > 0 {
				avg_tc_on_way <- (sum_tc_on_way / (cycle));
				if (tc_on_way > max_tc_on_way) {max_tc_on_way <- tc_on_way;}
				
				// get the usage (in percent) of this way of all members of ALL touring companys
				usage_percent <- count_tc_members_hiked_way / max([1,mb_total]);

				// categorize the usage_percent of the way
				if (usage_percent < usage_percent_category_lower * max(list_ways_usage_percent)) {
						usage_percent_category <- 10;
					} else if (usage_percent > usage_percent_category_upper * max(list_ways_usage_percent)) {
						usage_percent_category <- 30;
					} else {
						usage_percent_category <- 20;
				}
			}
		}
		
		// ****** CA: calculations, operations, periodically file-outputs
		ask ca {
			// statistical values
			list<tc>counted_tc <- inside(tc,self);
			tc_in_area <- length(counted_tc); 
			sum_tc_in_area <- sum_tc_in_area + length(counted_tc);
			tc_members_in_area <- sum(counted_tc collect(each.tc_members));
			sum_tc_members_in_area <- sum_tc_members_in_area + sum(counted_tc collect(each.tc_members));

			// loop over all counted tc in this area
			loop t over: counted_tc {

				// simple statistics: is this tc seen in this area?
				if (list_tc_hiked_area_once contains (string(int(t)))) {
					// previous cycle found
						remove string(int(t)) from:list_tc_hiked_area_once;
						add string(int(t)) to:list_tc_hiked_area_once;
					} else {
					// NO previous cycle found
						add string(int(t)) to:list_tc_hiked_area_once;
						count_tc_members_hiked_area_once <- count_tc_members_hiked_area_once + t.tc_members;
				}

				// complex statistics: is this tc seen more than one time in
				// this area divided by a break of at least one cycle?
				if ((list_tc_hiked_area contains (string(int(t))+"-"+string(cycle-1)))) {
					// previous cycle found
						remove string(int(t))+"-"+string(cycle-1) from:list_tc_hiked_area;
						add string(int(t))+"-"+string(cycle) to:list_tc_hiked_area;
					} else {
					// NO previous cycle found
						add string(int(t))+"-"+string(cycle) to:list_tc_hiked_area;
						count_tc_members_hiked_area <- count_tc_members_hiked_area + t.tc_members;

						// was this tc at the "Brockenplateau"?
						if (self.shape_objectid = 1) {
							// mark this tc
							t.was_inside_BROCKEN <- true;

							// count this tc at their home location
							if (t.tc_starttype = 'parking') {
									ask parking(first(t.list_tc_target_points)) {
										sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
										sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + t.tc_members;
									}
								} else if (t.tc_starttype = 'bus') {
									ask bus(first(t.list_tc_target_points)) {
										sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
										sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + t.tc_members;
									}
								} else if (t.tc_starttype = 'town') {
									ask towns(first(t.list_tc_target_points)) {
										sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
										sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + t.tc_members;
									}
							}
						}
				}
			}
			count_tc_hiked_area <- length(list_tc_hiked_area);
			count_tc_hiked_area_once <- length(list_tc_hiked_area_once);
		}

		// ****** HEATMAP: calculations, operations, periodically file-outputs
		ask heatmap {
			// statistical values
			list<tc>counted_tc <- tc inside(self);
			tc_in_heatmap <- length(counted_tc); 
			sum_tc_in_heatmap <- sum_tc_in_heatmap + length(counted_tc);
			tc_members_in_heatmap <- sum(counted_tc collect(each.tc_members));
			sum_tc_members_in_heatmap <- sum_tc_members_in_heatmap + sum(counted_tc collect(each.tc_members));

			// loop over all counted tc in this area
			loop t over: counted_tc {
				// complex statistics: is this tc seen more than one time in
				// this heatmap-area divided by a break of at least one cycle?
				if ((list_tc_hiked_heatmap contains (string(int(t))+"-"+string(cycle-1)))) {
					// previous cycle found
						remove string(int(t))+"-"+string(cycle-1) from:list_tc_hiked_heatmap;
						add string(int(t))+"-"+string(cycle) to:list_tc_hiked_heatmap;
					} else {
					// NO previous cycle found
						add string(int(t))+"-"+string(cycle) to:list_tc_hiked_heatmap;
						count_tc_members_hiked_heatmap <- count_tc_members_hiked_heatmap + t.tc_members;
				}
				count_tc_hiked_heatmap <- length(list_tc_hiked_heatmap);
			}
		}

		// ****** PARKING: calculations, operations, periodically file-outputs
		ask parking {
			// statistical values
			add tc_home_now to:list_tc_home_now;
			add tc_mb_home_now to:list_tc_mb_home_now;
		}

		// recalculate the weight-map for close to nature hikers
		do recalculate_ways;
		
		// several global calculations
		list_tc_members <- tc collect(each.tc_members);
		list_tc_restingattarget_cycles <- tc collect(each.tc_restingattarget_cycles);
		list_tc_destinationtype <- tc collect(each.tc_destinationtype);
		list_tc_startcycle <- tc collect(each.tc_startcycle);
		list_tc_max_hiking_distance <- tc collect(each.tc_max_hiking_distance);
		list_tc_hiked_distance <- tc collect(each.tc_hiked_distance);
		list_tc_standard_speed <- tc collect(each.speed);
		list_count_tc_members_hiked_area_1 <- ca where (each.shape_type='Revier') collect(each.count_tc_members_hiked_area);
		list_count_tc_members_hiked_area_2 <- ca where (each.shape_type='Bereich') collect(each.count_tc_members_hiked_area);
		list_count_tc_members_hiked_area_1_once <- ca where (each.shape_type='Revier') collect(each.count_tc_members_hiked_area_once);
		list_count_tc_members_hiked_area_2_once <- ca where (each.shape_type='Bereich') collect(each.count_tc_members_hiked_area_once);
		list_count_tc_members_hiked_way <- ways collect(each.count_tc_members_hiked_way);
		list_count_tc_members_hiked_heatmap <- heatmap collect(each.count_tc_members_hiked_heatmap);
		list_ways_usage_percent <- ways collect(each.usage_percent);
		list_ways_usage_percent_category <- ways collect(each.usage_percent_category);

		// special countings for touring companys which where at the Brocken
		count_brocken_members_TOTAL <-	parking[12].sum_tc_members_BROCKEN+parking[13].sum_tc_members_BROCKEN+parking[28].sum_tc_members_BROCKEN+bus[10].sum_tc_members_BROCKEN+bus[14].sum_tc_members_BROCKEN+towns[0].sum_tc_members_BROCKEN
																		+ parking[2].sum_tc_members_BROCKEN+parking[3].sum_tc_members_BROCKEN+bus[11].sum_tc_members_BROCKEN+towns[1].sum_tc_members_BROCKEN 
																		+ parking[6].sum_tc_members_BROCKEN+parking[7].sum_tc_members_BROCKEN+bus[23].sum_tc_members_BROCKEN
																		+ parking[27].sum_tc_members_BROCKEN+bus[18].sum_tc_members_BROCKEN+bus[19].sum_tc_members_BROCKEN+towns[2].sum_tc_members_BROCKEN
																		+ parking[20].sum_tc_members_BROCKEN+parking[21].sum_tc_members_BROCKEN+parking[22].sum_tc_members_BROCKEN+bus[1].sum_tc_members_BROCKEN+bus[2].sum_tc_members_BROCKEN+towns[3].sum_tc_members_BROCKEN
																		+ parking[17].sum_tc_members_BROCKEN+parking[19].sum_tc_members_BROCKEN+bus[3].sum_tc_members_BROCKEN+bus[4].sum_tc_members_BROCKEN
																		+ parking[14].sum_tc_members_BROCKEN+parking[15].sum_tc_members_BROCKEN+parking[16].sum_tc_members_BROCKEN+bus[8].sum_tc_members_BROCKEN+towns[4].sum_tc_members_BROCKEN
																		;
		if (count_brocken_members_TOTAL = 0) {count_brocken_members_TOTAL <- 1;}	

		count_brocken_members_percent_BADHARZBURG <- (parking[12].sum_tc_members_BROCKEN+parking[13].sum_tc_members_BROCKEN+parking[28].sum_tc_members_BROCKEN+bus[10].sum_tc_members_BROCKEN+bus[14].sum_tc_members_BROCKEN+towns[0].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_TORFHAUS <- (parking[2].sum_tc_members_BROCKEN+parking[3].sum_tc_members_BROCKEN+bus[11].sum_tc_members_BROCKEN+towns[1].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_ODERBRUECK <- (parking[6].sum_tc_members_BROCKEN+parking[7].sum_tc_members_BROCKEN+bus[23].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_BRAUNLAGE <- (parking[27].sum_tc_members_BROCKEN+bus[18].sum_tc_members_BROCKEN+bus[19].sum_tc_members_BROCKEN+towns[2].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_SCHIERKE <- (parking[20].sum_tc_members_BROCKEN+parking[21].sum_tc_members_BROCKEN+parking[22].sum_tc_members_BROCKEN+bus[1].sum_tc_members_BROCKEN+bus[2].sum_tc_members_BROCKEN+towns[3].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_DREIANNENHOHNE <- (parking[17].sum_tc_members_BROCKEN+parking[19].sum_tc_members_BROCKEN+bus[3].sum_tc_members_BROCKEN+bus[4].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;
		count_brocken_members_percent_ILSENBURG <- (parking[14].sum_tc_members_BROCKEN+parking[15].sum_tc_members_BROCKEN+parking[16].sum_tc_members_BROCKEN+bus[8].sum_tc_members_BROCKEN+towns[4].sum_tc_members_BROCKEN) / count_brocken_members_TOTAL;

		// save all peridodicla data to files
		do save_periodical_data;
		
		// after the first run, do no more writing of any header information to files: set the variable accordingly
		write_cvs_headers_at_first_time <- false;	

	}


	// ---------------------------------------------------------------------------------------
	// global:	save all peridodical data to files
	// ---------------------------------------------------------------------------------------
	action save_periodical_data {
		// periodical file output (when anything else is done)
		if (	save_periodical_files
					and (	cycle mod date_cycles_per_simulation_day = 0
								or cycle mod date_cycles_per_simulation_day = 143
					)
				){

			// ----- SOD: factors (for creating tc) and basic values
			string filename <- "days-factors.csv";
			if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
			if (write_cvs_headers_at_first_time) {
				save ("day,factor_season,factor_weekday,factor_holiday,calc_factor_weather,factor_weather_hikingspeed_today,calc_factor_parking,calc_factor_bus,calc_factor_town,calc_factor_train")
						to:file_output + filename rewrite:false type:"text";
			}
			if (mod(cycle,date_cycles_per_simulation_day) = 0) {
	 			save [	date_days,
	 							int(factor_season*10000)/10000,int(factor_weekday*10000)/10000,int(factor_holiday*10000)/10000,int(calc_factor_weather*10000)/10000,int(weather_hikingspeed_today_factor*10000)/10000,
	 							int(calc_factor_parking*10000)/10000,int(calc_factor_bus*10000)/10000,int(calc_factor_town*10000)/10000,int(calc_factor_train*10000)/10000,
	 							set_season_type
					] to:file_output + filename rewrite:false type:"csv";
			}
			// ----- SOD: number of created tc
			filename <- "days-tc.csv";
			if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
			if (write_cvs_headers_at_first_time) {
				save ("day,tc_parking,tc_parking_stopover,tc_bus,tc_town,tc_train,tc_destinationtype_target,tc_destinationtype_nature,tc_destinationtype_hwn")
						to:file_output + filename rewrite:false type:"text";
			}
			if (mod(cycle,date_cycles_per_simulation_day) = 0) {
	 			save [	date_days,
	 							int(calc_number_of_tc_parking*modeling_reduction_factor),int(calc_number_of_tc_parking_stopover*modeling_reduction_factor),int(calc_number_of_tc_bus*modeling_reduction_factor),int(calc_number_of_tc_town*modeling_reduction_factor),int(calc_number_of_tc_train*modeling_reduction_factor),
	 							int(tc count (each.tc_destinationtype = 'target')*modeling_reduction_factor),int(tc count (each.tc_destinationtype = 'nature')*modeling_reduction_factor),int(tc count (each.tc_destinationtype = 'hwn')*modeling_reduction_factor)
					] to:file_output + filename rewrite:false type:"csv";
			}

			// ----- EOD: statistical values for parking-areas
			ask parking {
				filename <- "days-parking-" + shape_id + "_" + shape_objectid + ".csv";
				if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
				if (write_cvs_headers_at_first_time) {
					save ("day,shape_id,shape_objectid,sum_tc_home,sum_tc_members_home,sum_tc_BROCKEN,sum_tc_members_BROCKEN,tc_home_min,tc_home_max,tc_home_mean,tc_home_halfrange,tc_mb_home_min,tc_mb_home_max,tc_mb_home_mean,tc_mb_home_halfrange,")
						to:file_output + filename rewrite:false type:"text";
				}

				// calculate some statistical values for the day before (EOD)
				if (mod(cycle,date_cycles_per_simulation_day) = 143) {
		 			save [	date_days,
		 							shape_id,shape_objectid,
		 							(sum_tc_home - sum_tc_home_last),(sum_tc_members_home - sum_tc_members_home_last),(sum_tc_BROCKEN - sum_tc_BROCKEN_last),(sum_tc_members_BROCKEN - sum_tc_members_BROCKEN_last),
		 							min(list_tc_home_now),max(list_tc_home_now),mean(list_tc_home_now),standard_deviation(list_tc_home_now),
		 							min(list_tc_mb_home_now),max(list_tc_mb_home_now),mean(list_tc_mb_home_now),standard_deviation(list_tc_mb_home_now)
									] to:file_output + filename rewrite:false type:"csv";
	
					// empty the statistical lists
					list_tc_home_now <- [];
					list_tc_mb_home_now <- [];

					// remember the last value
					sum_tc_home_last <- sum_tc_home;
					sum_tc_members_home_last <- sum_tc_members_home;
					sum_tc_BROCKEN_last <- sum_tc_BROCKEN;
					sum_tc_members_BROCKEN_last <- sum_tc_members_BROCKEN;

				}			
			}
			
			// ----- EOD: countingarea (ca) counts
			filename <- "days-ca.csv";
			if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
			if (write_cvs_headers_at_first_time) {
				save ("day,ca[0].shape_objectid,ca[0].shape_id,ca[0].count_tc_hiked_area_once, ca[0].count_tc_members_hiked_area_once, ca[0].count_tc_hiked_area, ca[0].count_tc_members_hiked_area,ca[0].percentage_mb_area,ca[1].shape_objectid,ca[1].shape_id,ca[1].count_tc_hiked_area_once,ca[1].count_tc_members_hiked_area_once, ca[1].count_tc_hiked_area, ca[1].count_tc_members_hiked_area,ca[1].percentage_mb_area,ca[2].shape_objectid,ca[2].shape_id,ca[2].count_tc_hiked_area_once, ca[2].count_tc_members_hiked_area_once, ca[2].count_tc_hiked_area, ca[2].count_tc_members_hiked_area,ca[2].percentage_mb_area,ca[3].shape_objectid,ca[3].shape_id,ca[3].count_tc_hiked_area_once, ca[3].count_tc_members_hiked_area_once, ca[3].count_tc_hiked_area, ca[3].count_tc_members_hiked_area,ca[3].percentage_mb_area,ca[4].shape_objectid,ca[4].shape_id,ca[4].count_tc_hiked_area_once, ca[4].count_tc_members_hiked_area_once, ca[4].count_tc_hiked_area, ca[4].count_tc_members_hiked_area,ca[4].percentage_mb_area,ca[5].shape_objectid,ca[5].shape_id,ca[5].count_tc_hiked_area_once, ca[5].count_tc_members_hiked_area_once, ca[5].count_tc_hiked_area, ca[5].count_tc_members_hiked_area,ca[5].percentage_mb_area,ca[6].shape_objectid,ca[6].shape_id,ca[6].count_tc_hiked_area_once, ca[6].count_tc_members_hiked_area_once, ca[6].count_tc_hiked_area, ca[6].count_tc_members_hiked_area,ca[6].percentage_mb_area,ca[7].shape_objectid,ca[7].shape_id,ca[7].count_tc_hiked_area_once, ca[7].count_tc_members_hiked_area_once, ca[7].count_tc_hiked_area, ca[7].count_tc_members_hiked_area,ca[7].percentage_mb_area,ca[8].shape_objectid,ca[8].shape_id,ca[8].count_tc_hiked_area_once, ca[8].count_tc_members_hiked_area_once, ca[8].count_tc_hiked_area, ca[8].count_tc_members_hiked_area,ca[8].percentage_mb_area,ca[9].shape_objectid,ca[9].shape_id,ca[9].count_tc_hiked_area_once, ca[9].count_tc_members_hiked_area_once, ca[9].count_tc_hiked_area, ca[9].count_tc_members_hiked_area,ca[9].percentage_mb_area,ca[10].shape_objectid,ca[10].shape_id,ca[10].count_tc_hiked_area_once, ca[10].count_tc_members_hiked_area_once, ca[10].count_tc_hiked_area, ca[10].count_tc_members_hiked_area,ca[10].percentage_mb_area,ca[11].shape_objectid,ca[11].shape_id,ca[11].count_tc_hiked_area_once, ca[11].count_tc_members_hiked_area_once, ca[11].count_tc_hiked_area, ca[11].count_tc_members_hiked_area,ca[11].percentage_mb_area,ca[12].shape_objectid,ca[12].shape_id,ca[12].count_tc_hiked_area_once, ca[12].count_tc_members_hiked_area_once, ca[12].count_tc_hiked_area, ca[12].count_tc_members_hiked_area,ca[12].percentage_mb_area")
					to:file_output + filename rewrite:false type:"text";
			}
			if (mod(cycle,date_cycles_per_simulation_day) = 143) {
	 			save [	date_days,
								ca[0].shape_objectid,ca[0].shape_id,ca[0].count_tc_hiked_area_once, ca[0].count_tc_members_hiked_area_once, ca[0].count_tc_hiked_area, ca[0].count_tc_members_hiked_area,ca[0].percentage_mb_area,
								ca[1].shape_objectid,ca[1].shape_id,ca[1].count_tc_hiked_area_once, ca[1].count_tc_members_hiked_area_once, ca[1].count_tc_hiked_area, ca[1].count_tc_members_hiked_area,ca[1].percentage_mb_area,
								ca[2].shape_objectid,ca[2].shape_id,ca[2].count_tc_hiked_area_once, ca[2].count_tc_members_hiked_area_once, ca[2].count_tc_hiked_area, ca[2].count_tc_members_hiked_area,ca[2].percentage_mb_area,
								ca[3].shape_objectid,ca[3].shape_id,ca[3].count_tc_hiked_area_once, ca[3].count_tc_members_hiked_area_once, ca[3].count_tc_hiked_area, ca[3].count_tc_members_hiked_area,ca[3].percentage_mb_area,
								ca[4].shape_objectid,ca[4].shape_id,ca[4].count_tc_hiked_area_once, ca[4].count_tc_members_hiked_area_once, ca[4].count_tc_hiked_area, ca[4].count_tc_members_hiked_area,ca[4].percentage_mb_area,
								ca[5].shape_objectid,ca[5].shape_id,ca[5].count_tc_hiked_area_once, ca[5].count_tc_members_hiked_area_once, ca[5].count_tc_hiked_area, ca[5].count_tc_members_hiked_area,ca[5].percentage_mb_area,
								ca[6].shape_objectid,ca[6].shape_id,ca[6].count_tc_hiked_area_once, ca[6].count_tc_members_hiked_area_once, ca[6].count_tc_hiked_area, ca[6].count_tc_members_hiked_area,ca[6].percentage_mb_area,
								ca[7].shape_objectid,ca[7].shape_id,ca[7].count_tc_hiked_area_once, ca[7].count_tc_members_hiked_area_once, ca[7].count_tc_hiked_area, ca[7].count_tc_members_hiked_area,ca[7].percentage_mb_area,
								ca[8].shape_objectid,ca[8].shape_id,ca[8].count_tc_hiked_area_once, ca[8].count_tc_members_hiked_area_once, ca[8].count_tc_hiked_area, ca[8].count_tc_members_hiked_area,ca[8].percentage_mb_area,
								ca[9].shape_objectid,ca[9].shape_id,ca[9].count_tc_hiked_area_once, ca[9].count_tc_members_hiked_area_once, ca[9].count_tc_hiked_area, ca[9].count_tc_members_hiked_area,ca[9].percentage_mb_area,
								ca[10].shape_objectid,ca[10].shape_id,ca[10].count_tc_hiked_area_once, ca[10].count_tc_members_hiked_area_once, ca[10].count_tc_hiked_area, ca[10].count_tc_members_hiked_area,ca[10].percentage_mb_area,
								ca[11].shape_objectid,ca[11].shape_id,ca[11].count_tc_hiked_area_once, ca[11].count_tc_members_hiked_area_once, ca[11].count_tc_hiked_area, ca[11].count_tc_members_hiked_area,ca[11].percentage_mb_area,
								ca[12].shape_objectid,ca[12].shape_id,ca[12].count_tc_hiked_area_once, ca[12].count_tc_members_hiked_area_once, ca[12].count_tc_hiked_area, ca[12].count_tc_members_hiked_area,ca[12].percentage_mb_area					
								] to:file_output + filename rewrite:false type:"csv";
			}

			// ----- EOD: countingpoints (cp) counts
			filename <- "days-cp.csv";
			if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
			if (write_cvs_headers_at_first_time) {
				save ("day,cp[0].shape_id,cp[0].shape_objectid,cp[0].shape_cp,cp[0].shape_subpoint,cp[0].sum_tc_at_cp,cp[0].sum_tc_heading_dir1,cp[0].sum_tc_heading_dir2,cp[0].sum_tc_members_at_cp,cp[0].sum_tc_members_heading_dir1,cp[0].sum_tc_members_heading_dir2,cp[1].shape_id,cp[1].shape_objectid,cp[1].shape_cp,cp[1].shape_subpoint,cp[1].sum_tc_at_cp,cp[1].sum_tc_heading_dir1,cp[1].sum_tc_heading_dir2,cp[1].sum_tc_members_at_cp,cp[1].sum_tc_members_heading_dir1,cp[1].sum_tc_members_heading_dir2,cp[2].shape_id,cp[2].shape_objectid,cp[2].shape_cp,cp[2].shape_subpoint,cp[2].sum_tc_at_cp,cp[2].sum_tc_heading_dir1,cp[2].sum_tc_heading_dir2,cp[2].sum_tc_members_at_cp,cp[2].sum_tc_members_heading_dir1,cp[2].sum_tc_members_heading_dir2,cp[3].shape_id,cp[3].shape_objectid,cp[3].shape_cp,cp[3].shape_subpoint,cp[3].sum_tc_at_cp,cp[3].sum_tc_heading_dir1,cp[3].sum_tc_heading_dir2,cp[3].sum_tc_members_at_cp,cp[3].sum_tc_members_heading_dir1,cp[3].sum_tc_members_heading_dir2,cp[4].shape_id,cp[4].shape_objectid,cp[4].shape_cp,cp[4].shape_subpoint,cp[4].sum_tc_at_cp,cp[4].sum_tc_heading_dir1,cp[4].sum_tc_heading_dir2,cp[4].sum_tc_members_at_cp,cp[4].sum_tc_members_heading_dir1,cp[4].sum_tc_members_heading_dir2,cp[5].shape_id,cp[5].shape_objectid,cp[5].shape_cp,cp[5].shape_subpoint,cp[5].sum_tc_at_cp,cp[5].sum_tc_heading_dir1,cp[5].sum_tc_heading_dir2,cp[5].sum_tc_members_at_cp,cp[5].sum_tc_members_heading_dir1,cp[5].sum_tc_members_heading_dir2,cp[6].shape_id,cp[6].shape_objectid,cp[6].shape_cp,cp[6].shape_subpoint,cp[6].sum_tc_at_cp,cp[6].sum_tc_heading_dir1,cp[6].sum_tc_heading_dir2,cp[6].sum_tc_members_at_cp,cp[6].sum_tc_members_heading_dir1,cp[6].sum_tc_members_heading_dir2,cp[7].shape_id,cp[7].shape_objectid,cp[7].shape_cp,cp[7].shape_subpoint,cp[7].sum_tc_at_cp,cp[7].sum_tc_heading_dir1,cp[7].sum_tc_heading_dir2,cp[7].sum_tc_members_at_cp,cp[7].sum_tc_members_heading_dir1,cp[7].sum_tc_members_heading_dir2,cp[8].shape_id,cp[8].shape_objectid,cp[8].shape_cp,cp[8].shape_subpoint,cp[8].sum_tc_at_cp,cp[8].sum_tc_heading_dir1,cp[8].sum_tc_heading_dir2,cp[8].sum_tc_members_at_cp,cp[8].sum_tc_members_heading_dir1,cp[8].sum_tc_members_heading_dir2,cp[9].shape_id,cp[9].shape_objectid,cp[9].shape_cp,cp[9].shape_subpoint,cp[9].sum_tc_at_cp,cp[9].sum_tc_heading_dir1,cp[9].sum_tc_heading_dir2,cp[9].sum_tc_members_at_cp,cp[9].sum_tc_members_heading_dir1,cp[9].sum_tc_members_heading_dir2,cp[10].shape_id,cp[10].shape_objectid,cp[10].shape_cp,cp[10].shape_subpoint,cp[10].sum_tc_at_cp,cp[10].sum_tc_heading_dir1,cp[10].sum_tc_heading_dir2,cp[10].sum_tc_members_at_cp,cp[10].sum_tc_members_heading_dir1,cp[10].sum_tc_members_heading_dir2,cp[11].shape_id,cp[11].shape_objectid,cp[11].shape_cp,cp[11].shape_subpoint,cp[11].sum_tc_at_cp,cp[11].sum_tc_heading_dir1,cp[11].sum_tc_heading_dir2,cp[11].sum_tc_members_at_cp,cp[11].sum_tc_members_heading_dir1,cp[11].sum_tc_members_heading_dir2,cp[12].shape_id,cp[12].shape_objectid,cp[12].shape_cp,cp[12].shape_subpoint,cp[12].sum_tc_at_cp,cp[12].sum_tc_heading_dir1,cp[12].sum_tc_heading_dir2,cp[12].sum_tc_members_at_cp,cp[12].sum_tc_members_heading_dir1,cp[12].sum_tc_members_heading_dir2,cp[13].shape_id,cp[13].shape_objectid,cp[13].shape_cp,cp[13].shape_subpoint,cp[13].sum_tc_at_cp,cp[13].sum_tc_heading_dir1,cp[13].sum_tc_heading_dir2,cp[13].sum_tc_members_at_cp,cp[13].sum_tc_members_heading_dir1,cp[13].sum_tc_members_heading_dir2,cp[14].shape_id,cp[14].shape_objectid,cp[14].shape_cp,cp[14].shape_subpoint,cp[14].sum_tc_at_cp,cp[14].sum_tc_heading_dir1,cp[14].sum_tc_heading_dir2,cp[14].sum_tc_members_at_cp,cp[14].sum_tc_members_heading_dir1,cp[14].sum_tc_members_heading_dir2,cp[15].shape_id,cp[15].shape_objectid,cp[15].shape_cp,cp[15].shape_subpoint,cp[15].sum_tc_at_cp,cp[15].sum_tc_heading_dir1,cp[15].sum_tc_heading_dir2,cp[15].sum_tc_members_at_cp,cp[15].sum_tc_members_heading_dir1,cp[15].sum_tc_members_heading_dir2,cp[16].shape_id,cp[16].shape_objectid,cp[16].shape_cp,cp[16].shape_subpoint,cp[16].sum_tc_at_cp,cp[16].sum_tc_heading_dir1,cp[16].sum_tc_heading_dir2,cp[16].sum_tc_members_at_cp,cp[16].sum_tc_members_heading_dir1,cp[16].sum_tc_members_heading_dir2,cp[17].shape_id,cp[17].shape_objectid,cp[17].shape_cp,cp[17].shape_subpoint,cp[17].sum_tc_at_cp,cp[17].sum_tc_heading_dir1,cp[17].sum_tc_heading_dir2,cp[17].sum_tc_members_at_cp,cp[17].sum_tc_members_heading_dir1,cp[17].sum_tc_members_heading_dir2,cp[18].shape_id,cp[18].shape_objectid,cp[18].shape_cp,cp[18].shape_subpoint,cp[18].sum_tc_at_cp,cp[18].sum_tc_heading_dir1,cp[18].sum_tc_heading_dir2,cp[18].sum_tc_members_at_cp,cp[18].sum_tc_members_heading_dir1,cp[18].sum_tc_members_heading_dir2,cp[19].shape_id,cp[19].shape_objectid,cp[19].shape_cp,cp[19].shape_subpoint,cp[19].sum_tc_at_cp,cp[19].sum_tc_heading_dir1,cp[19].sum_tc_heading_dir2,cp[19].sum_tc_members_at_cp,cp[19].sum_tc_members_heading_dir1,cp[19].sum_tc_members_heading_dir2,cp[20].shape_id,cp[20].shape_objectid,cp[20].shape_cp,cp[20].shape_subpoint,cp[20].sum_tc_at_cp,cp[20].sum_tc_heading_dir1,cp[20].sum_tc_heading_dir2,cp[20].sum_tc_members_at_cp,cp[20].sum_tc_members_heading_dir1,cp[20].sum_tc_members_heading_dir2,cp[21].shape_id,cp[21].shape_objectid,cp[21].shape_cp,cp[21].shape_subpoint,cp[21].sum_tc_at_cp,cp[21].sum_tc_heading_dir1,cp[21].sum_tc_heading_dir2,cp[21].sum_tc_members_at_cp,cp[21].sum_tc_members_heading_dir1,cp[21].sum_tc_members_heading_dir2,cp[22].shape_id,cp[22].shape_objectid,cp[22].shape_cp,cp[22].shape_subpoint,cp[22].sum_tc_at_cp,cp[22].sum_tc_heading_dir1,cp[22].sum_tc_heading_dir2,cp[22].sum_tc_members_at_cp,cp[22].sum_tc_members_heading_dir1,cp[22].sum_tc_members_heading_dir2,cp[23].shape_id,cp[23].shape_objectid,cp[23].shape_cp,cp[23].shape_subpoint,cp[23].sum_tc_at_cp,cp[23].sum_tc_heading_dir1,cp[23].sum_tc_heading_dir2,cp[23].sum_tc_members_at_cp,cp[23].sum_tc_members_heading_dir1,cp[23].sum_tc_members_heading_dir2,cp[24].shape_id,cp[24].shape_objectid,cp[24].shape_cp,cp[24].shape_subpoint,cp[24].sum_tc_at_cp,cp[24].sum_tc_heading_dir1,cp[24].sum_tc_heading_dir2,cp[24].sum_tc_members_at_cp,cp[24].sum_tc_members_heading_dir1,cp[24].sum_tc_members_heading_dir2,cp[25].shape_id,cp[25].shape_objectid,cp[25].shape_cp,cp[25].shape_subpoint,cp[25].sum_tc_at_cp,cp[25].sum_tc_heading_dir1,cp[25].sum_tc_heading_dir2,cp[25].sum_tc_members_at_cp,cp[25].sum_tc_members_heading_dir1,cp[25].sum_tc_members_heading_dir2,cp[26].shape_id,cp[26].shape_objectid,cp[26].shape_cp,cp[26].shape_subpoint,cp[26].sum_tc_at_cp,cp[26].sum_tc_heading_dir1,cp[26].sum_tc_heading_dir2,cp[26].sum_tc_members_at_cp,cp[26].sum_tc_members_heading_dir1,cp[26].sum_tc_members_heading_dir2,cp[27].shape_id,cp[27].shape_objectid,cp[27].shape_cp,cp[27].shape_subpoint,cp[27].sum_tc_at_cp,cp[27].sum_tc_heading_dir1,cp[27].sum_tc_heading_dir2,cp[27].sum_tc_members_at_cp,cp[27].sum_tc_members_heading_dir1,cp[27].sum_tc_members_heading_dir2,cp[28].shape_id,cp[28].shape_objectid,cp[28].shape_cp,cp[28].shape_subpoint,cp[28].sum_tc_at_cp,cp[28].sum_tc_heading_dir1,cp[28].sum_tc_heading_dir2,cp[28].sum_tc_members_at_cp,cp[28].sum_tc_members_heading_dir1,cp[28].sum_tc_members_heading_dir2,cp[29].shape_id,cp[29].shape_objectid,cp[29].shape_cp,cp[29].shape_subpoint,cp[29].sum_tc_at_cp,cp[29].sum_tc_heading_dir1,cp[29].sum_tc_heading_dir2,cp[29].sum_tc_members_at_cp,cp[29].sum_tc_members_heading_dir1,cp[29].sum_tc_members_heading_dir2,cp[30].shape_id,cp[30].shape_objectid,cp[30].shape_cp,cp[30].shape_subpoint,cp[30].sum_tc_at_cp,cp[30].sum_tc_heading_dir1,cp[30].sum_tc_heading_dir2,cp[30].sum_tc_members_at_cp,cp[30].sum_tc_members_heading_dir1,cp[30].sum_tc_members_heading_dir2,cp[31].shape_id,cp[31].shape_objectid,cp[31].shape_cp,cp[31].shape_subpoint,cp[31].sum_tc_at_cp,cp[31].sum_tc_heading_dir1,cp[31].sum_tc_heading_dir2,cp[31].sum_tc_members_at_cp,cp[31].sum_tc_members_heading_dir1,cp[31].sum_tc_members_heading_dir2")
						to:file_output + filename rewrite:false type:"text";
			}
			if (mod(cycle,date_cycles_per_simulation_day) = 143) {
				save [	date_days,
								cp[0].shape_id,cp[0].shape_objectid,cp[0].shape_cp,cp[0].shape_subpoint,cp[0].sum_tc_at_cp, cp[0].sum_tc_heading_dir1, cp[0].sum_tc_heading_dir2, cp[0].sum_tc_members_at_cp, cp[0].sum_tc_members_heading_dir1, cp[0].sum_tc_members_heading_dir2,
								cp[1].shape_id,cp[1].shape_objectid,cp[1].shape_cp,cp[1].shape_subpoint,cp[1].sum_tc_at_cp, cp[1].sum_tc_heading_dir1, cp[1].sum_tc_heading_dir2, cp[1].sum_tc_members_at_cp, cp[1].sum_tc_members_heading_dir1, cp[1].sum_tc_members_heading_dir2,
								cp[2].shape_id,cp[2].shape_objectid,cp[2].shape_cp,cp[2].shape_subpoint,cp[2].sum_tc_at_cp, cp[2].sum_tc_heading_dir1, cp[2].sum_tc_heading_dir2, cp[2].sum_tc_members_at_cp, cp[2].sum_tc_members_heading_dir1, cp[2].sum_tc_members_heading_dir2,
								cp[3].shape_id,cp[3].shape_objectid,cp[3].shape_cp,cp[3].shape_subpoint,cp[3].sum_tc_at_cp, cp[3].sum_tc_heading_dir1, cp[3].sum_tc_heading_dir2, cp[3].sum_tc_members_at_cp, cp[3].sum_tc_members_heading_dir1, cp[3].sum_tc_members_heading_dir2,
								cp[4].shape_id,cp[4].shape_objectid,cp[4].shape_cp,cp[4].shape_subpoint,cp[4].sum_tc_at_cp, cp[4].sum_tc_heading_dir1, cp[4].sum_tc_heading_dir2, cp[4].sum_tc_members_at_cp, cp[4].sum_tc_members_heading_dir1, cp[4].sum_tc_members_heading_dir2,
								cp[5].shape_id,cp[5].shape_objectid,cp[5].shape_cp,cp[5].shape_subpoint,cp[5].sum_tc_at_cp, cp[5].sum_tc_heading_dir1, cp[5].sum_tc_heading_dir2, cp[5].sum_tc_members_at_cp, cp[5].sum_tc_members_heading_dir1, cp[5].sum_tc_members_heading_dir2,
								cp[6].shape_id,cp[6].shape_objectid,cp[6].shape_cp,cp[6].shape_subpoint,cp[6].sum_tc_at_cp, cp[6].sum_tc_heading_dir1, cp[6].sum_tc_heading_dir2, cp[6].sum_tc_members_at_cp, cp[6].sum_tc_members_heading_dir1, cp[6].sum_tc_members_heading_dir2,
								cp[7].shape_id,cp[7].shape_objectid,cp[7].shape_cp,cp[7].shape_subpoint,cp[7].sum_tc_at_cp, cp[7].sum_tc_heading_dir1, cp[7].sum_tc_heading_dir2, cp[7].sum_tc_members_at_cp, cp[7].sum_tc_members_heading_dir1, cp[7].sum_tc_members_heading_dir2,
								cp[8].shape_id,cp[8].shape_objectid,cp[8].shape_cp,cp[8].shape_subpoint,cp[8].sum_tc_at_cp, cp[8].sum_tc_heading_dir1, cp[8].sum_tc_heading_dir2, cp[8].sum_tc_members_at_cp, cp[8].sum_tc_members_heading_dir1, cp[8].sum_tc_members_heading_dir2,
								cp[9].shape_id,cp[9].shape_objectid,cp[9].shape_cp,cp[9].shape_subpoint,cp[9].sum_tc_at_cp, cp[9].sum_tc_heading_dir1, cp[9].sum_tc_heading_dir2, cp[9].sum_tc_members_at_cp, cp[9].sum_tc_members_heading_dir1, cp[9].sum_tc_members_heading_dir2,
								cp[10].shape_id,cp[10].shape_objectid,cp[10].shape_cp,cp[10].shape_subpoint,cp[10].sum_tc_at_cp, cp[10].sum_tc_heading_dir1, cp[10].sum_tc_heading_dir2, cp[10].sum_tc_members_at_cp, cp[10].sum_tc_members_heading_dir1, cp[10].sum_tc_members_heading_dir2,
								cp[11].shape_id,cp[11].shape_objectid,cp[11].shape_cp,cp[11].shape_subpoint,cp[11].sum_tc_at_cp, cp[11].sum_tc_heading_dir1, cp[11].sum_tc_heading_dir2, cp[11].sum_tc_members_at_cp, cp[11].sum_tc_members_heading_dir1, cp[11].sum_tc_members_heading_dir2,
								cp[12].shape_id,cp[12].shape_objectid,cp[12].shape_cp,cp[12].shape_subpoint,cp[12].sum_tc_at_cp, cp[12].sum_tc_heading_dir1, cp[12].sum_tc_heading_dir2, cp[12].sum_tc_members_at_cp, cp[12].sum_tc_members_heading_dir1, cp[12].sum_tc_members_heading_dir2,
								cp[13].shape_id,cp[13].shape_objectid,cp[13].shape_cp,cp[13].shape_subpoint,cp[13].sum_tc_at_cp, cp[13].sum_tc_heading_dir1, cp[13].sum_tc_heading_dir2, cp[13].sum_tc_members_at_cp, cp[13].sum_tc_members_heading_dir1, cp[13].sum_tc_members_heading_dir2,
								cp[14].shape_id,cp[14].shape_objectid,cp[14].shape_cp,cp[14].shape_subpoint,cp[14].sum_tc_at_cp, cp[14].sum_tc_heading_dir1, cp[14].sum_tc_heading_dir2, cp[14].sum_tc_members_at_cp, cp[14].sum_tc_members_heading_dir1, cp[14].sum_tc_members_heading_dir2,
								cp[15].shape_id,cp[15].shape_objectid,cp[15].shape_cp,cp[15].shape_subpoint,cp[15].sum_tc_at_cp, cp[15].sum_tc_heading_dir1, cp[15].sum_tc_heading_dir2, cp[15].sum_tc_members_at_cp, cp[15].sum_tc_members_heading_dir1, cp[15].sum_tc_members_heading_dir2,
								cp[16].shape_id,cp[16].shape_objectid,cp[16].shape_cp,cp[16].shape_subpoint,cp[16].sum_tc_at_cp, cp[16].sum_tc_heading_dir1, cp[16].sum_tc_heading_dir2, cp[16].sum_tc_members_at_cp, cp[16].sum_tc_members_heading_dir1, cp[16].sum_tc_members_heading_dir2,
								cp[17].shape_id,cp[17].shape_objectid,cp[17].shape_cp,cp[17].shape_subpoint,cp[17].sum_tc_at_cp, cp[17].sum_tc_heading_dir1, cp[17].sum_tc_heading_dir2, cp[17].sum_tc_members_at_cp, cp[17].sum_tc_members_heading_dir1, cp[17].sum_tc_members_heading_dir2,
								cp[18].shape_id,cp[18].shape_objectid,cp[18].shape_cp,cp[18].shape_subpoint,cp[18].sum_tc_at_cp, cp[18].sum_tc_heading_dir1, cp[18].sum_tc_heading_dir2, cp[18].sum_tc_members_at_cp, cp[18].sum_tc_members_heading_dir1, cp[18].sum_tc_members_heading_dir2,
								cp[19].shape_id,cp[19].shape_objectid,cp[19].shape_cp,cp[19].shape_subpoint,cp[19].sum_tc_at_cp, cp[19].sum_tc_heading_dir1, cp[19].sum_tc_heading_dir2, cp[19].sum_tc_members_at_cp, cp[19].sum_tc_members_heading_dir1, cp[19].sum_tc_members_heading_dir2,
								cp[20].shape_id,cp[20].shape_objectid,cp[20].shape_cp,cp[20].shape_subpoint,cp[20].sum_tc_at_cp, cp[20].sum_tc_heading_dir1, cp[20].sum_tc_heading_dir2, cp[20].sum_tc_members_at_cp, cp[20].sum_tc_members_heading_dir1, cp[20].sum_tc_members_heading_dir2,
								cp[21].shape_id,cp[21].shape_objectid,cp[21].shape_cp,cp[21].shape_subpoint,cp[21].sum_tc_at_cp, cp[21].sum_tc_heading_dir1, cp[21].sum_tc_heading_dir2, cp[21].sum_tc_members_at_cp, cp[21].sum_tc_members_heading_dir1, cp[21].sum_tc_members_heading_dir2,
								cp[22].shape_id,cp[22].shape_objectid,cp[22].shape_cp,cp[22].shape_subpoint,cp[22].sum_tc_at_cp, cp[22].sum_tc_heading_dir1, cp[22].sum_tc_heading_dir2, cp[22].sum_tc_members_at_cp, cp[22].sum_tc_members_heading_dir1, cp[22].sum_tc_members_heading_dir2,
								cp[23].shape_id,cp[23].shape_objectid,cp[23].shape_cp,cp[23].shape_subpoint,cp[23].sum_tc_at_cp, cp[23].sum_tc_heading_dir1, cp[23].sum_tc_heading_dir2, cp[23].sum_tc_members_at_cp, cp[23].sum_tc_members_heading_dir1, cp[23].sum_tc_members_heading_dir2,
								cp[24].shape_id,cp[24].shape_objectid,cp[24].shape_cp,cp[24].shape_subpoint,cp[24].sum_tc_at_cp, cp[24].sum_tc_heading_dir1, cp[24].sum_tc_heading_dir2, cp[24].sum_tc_members_at_cp, cp[24].sum_tc_members_heading_dir1, cp[24].sum_tc_members_heading_dir2,
								cp[25].shape_id,cp[25].shape_objectid,cp[25].shape_cp,cp[25].shape_subpoint,cp[25].sum_tc_at_cp, cp[25].sum_tc_heading_dir1, cp[25].sum_tc_heading_dir2, cp[25].sum_tc_members_at_cp, cp[25].sum_tc_members_heading_dir1, cp[25].sum_tc_members_heading_dir2,
								cp[26].shape_id,cp[26].shape_objectid,cp[26].shape_cp,cp[26].shape_subpoint,cp[26].sum_tc_at_cp, cp[26].sum_tc_heading_dir1, cp[26].sum_tc_heading_dir2, cp[26].sum_tc_members_at_cp, cp[26].sum_tc_members_heading_dir1, cp[26].sum_tc_members_heading_dir2,
								cp[27].shape_id,cp[27].shape_objectid,cp[27].shape_cp,cp[27].shape_subpoint,cp[27].sum_tc_at_cp, cp[27].sum_tc_heading_dir1, cp[27].sum_tc_heading_dir2, cp[27].sum_tc_members_at_cp, cp[27].sum_tc_members_heading_dir1, cp[27].sum_tc_members_heading_dir2,
								cp[28].shape_id,cp[28].shape_objectid,cp[28].shape_cp,cp[28].shape_subpoint,cp[28].sum_tc_at_cp, cp[28].sum_tc_heading_dir1, cp[28].sum_tc_heading_dir2, cp[28].sum_tc_members_at_cp, cp[28].sum_tc_members_heading_dir1, cp[28].sum_tc_members_heading_dir2,
								cp[29].shape_id,cp[29].shape_objectid,cp[29].shape_cp,cp[29].shape_subpoint,cp[29].sum_tc_at_cp, cp[29].sum_tc_heading_dir1, cp[29].sum_tc_heading_dir2, cp[29].sum_tc_members_at_cp, cp[29].sum_tc_members_heading_dir1, cp[29].sum_tc_members_heading_dir2,
								cp[30].shape_id,cp[30].shape_objectid,cp[30].shape_cp,cp[30].shape_subpoint,cp[30].sum_tc_at_cp, cp[30].sum_tc_heading_dir1, cp[30].sum_tc_heading_dir2, cp[30].sum_tc_members_at_cp, cp[30].sum_tc_members_heading_dir1, cp[30].sum_tc_members_heading_dir2,
								cp[31].shape_id,cp[31].shape_objectid,cp[31].shape_cp,cp[31].shape_subpoint,cp[31].sum_tc_at_cp, cp[31].sum_tc_heading_dir1, cp[31].sum_tc_heading_dir2, cp[31].sum_tc_members_at_cp, cp[31].sum_tc_members_heading_dir1, cp[31].sum_tc_members_heading_dir2
								] to:file_output + filename rewrite:false type:"csv";
			}

		}

	}


	// ---------------------------------------------------------------------------------------
	// global:	start a new day
	// ---------------------------------------------------------------------------------------
	action start_a_new_day {

			// calculate all factors
			factor_weekday <- 1.00;
			if (year_infos[2,date_days] = 'Sa' or year_infos[2,date_days] = 'Su') {
				factor_weekday <- factor_weekday_value;
			}
			factor_season <- float(year_infos[3,date_days]);
			factor_holiday <- max([1.0,float(year_infos[4,date_days]) * factor_holiday_value]);

			// calculate all cycle infos
			tc_startcycle_mean <- int(year_infos[5,date_days]);
			tc_startcycle_halfrange <- int(year_infos[6,date_days]);
			tc_lastlightcycle <- int(year_infos[7,date_days]);
			tc_startcycle_mean_stopover <- int(year_infos[8,date_days]);
			tc_startcycle_halfrange_stopover <- int(year_infos[9,date_days]);
			possible_winter <- int(year_infos[10,date_days]);

			// correct the lastlight value to have some spare time to get back home again at the evening
			if (tc_lastlightcycle > 135) {
				   tc_lastlightcycle <-  135;
			}

			// is the actual winter_period over?
			if (remaining_winter_days > 1) {
					remaining_winter_days <- remaining_winter_days - 1;
					total_winter_days <- total_winter_days + 1; 
				} else if (remaining_winter_days = 1) {
					// the winter-period is over, return back for summer
					remaining_winter_days <- 0;
					// summer: activate the ways for the simulation_year and start with "summer"-setting
					do activate_ways_and_pois (simulation_year, 'summer');
			}

			// do we have (a new) winter-period or summer (which influences the choosen ways)
			if (not ACTIVATESUMMER
					and not ACTIVITYWINTERDAYS) {
				if (	possible_winter = 1
							and remaining_winter_days = 0
							and flip(proba_winter_period)
				) {
					// winter: activate the ways for the simulation_year with "winter"-setting
					do activate_ways_and_pois (simulation_year, 'winter');
					remaining_winter_days <- int(truncated_gauss({winter_period_mean,winter_period_halfrange}));
				}
			}

			// do some calculations (smoothed value) and get random values for the weather
			calc_factor_weather <-	weather_factors_list[int(get_random_value_of_weighted_list (weather_factor_weighted_list))] * factor_weather_smoothing_value
															+ calc_factor_weather_lastcycle * (1 - factor_weather_smoothing_value);
			calc_factor_weather_lastcycle <- calc_factor_weather;
	
			// what is the influence of the weather to the hiking speed?
			if (calc_factor_weather >= weather_factor_condition_good) {
					// good weather decreases the hikingspeed
					weather_hikingspeed_today_factor <- weather_hikingspeed_factor_good;
				} else if (calc_factor_weather <= weather_factor_condition_bad) {
					// bad weather increases the hikingspeed
					weather_hikingspeed_today_factor <- weather_hikingspeed_factor_bad;
				} else{
					// normal weather leave it untouched
					weather_hikingspeed_today_factor <- weather_hikingspeed_factor_normal;
			}

			// are there any tc which were NOT back home (they are a little bit late, hm)?
			if (tc count(each.name != nil) != 0) {
				write ("## THERE ARE TC NOT BACK HOME: " + tc count(each.name != nil));

				// kill those tc, they are lost in the darkness somewhere in the wilderness *smile*
				ask tc {
					total_tc_mb_late <- total_tc_mb_late + tc_members;
					total_tc_late <- total_tc_late + 1;

					// say "Good Bye"
					do die;
				}
			}

			// cleanup and FREE space all places where there might be some tc left over
			ask parking {tc_home_now <- 0; tc_mb_home_now <- 0;}
			ask bus {tc_home_now <- 0;}
			ask towns {tc_home_now <- 0;}
			ask train {tc_home_now <- 0;}

			// write a new day message to the console
			write "========== day=" + year_infos[0,date_days] + ", date=" + year_infos[1,date_days] + ", weekday=" + year_infos[2,date_days] + ", season=" + year_infos[3,date_days] + ", holiday=" + year_infos[4,date_days] + ", start_mean=" + year_infos[5,date_days] + ", start_halfrange=" + year_infos[6,date_days] + ", lastlight=" + year_infos[7,date_days] + ", start_mean_stopover=" + year_infos[8,date_days] + ", start_halfrange_stopover=" + year_infos[9,date_days] + ", possible_winter=" + year_infos[10,date_days] ;

			// CREATE NEW TC starting at parking-areas (1), subtype = hiking
			calc_factor_parking <- int(10000 * factor_holiday * factor_weekday * factor_season * calc_factor_weather)/10000;
			calc_number_of_tc_parking <- int(truncated_gauss({int(standard_number_of_tc_parking / modeling_reduction_factor * calc_factor_parking),int(standard_number_of_tc_parking / modeling_reduction_factor * calc_factor_parking) * calc_number_of_tc_halfrange_factor}));
			if (FIXEDQUANTITIES) {
				calc_factor_parking <- int(10000 * factor_holiday * factor_weekday * factor_season)/10000;
				calc_number_of_tc_parking <- int(standard_number_of_tc_parking / modeling_reduction_factor * calc_factor_parking);
			}
			if (DRYRUNMODE) {calc_number_of_tc_parking <- 0;}
			if (not BUGFIXMODE) {
					write "# [" + (date_days) + "] CREATING with factor " + calc_factor_parking with_precision 4 + " the number of " + calc_number_of_tc_parking + " (" + int(calc_number_of_tc_parking*modeling_reduction_factor) + ") NEW TC for PARKING-AREAS";
					do create_tc (calc_number_of_tc_parking,'parking','hiking');
				} else {
					write "BF# [" + (date_days) + "] CREATING with factor " + calc_factor_parking with_precision 4 + " the number of " + calc_number_of_tc_parking + " (" + int(calc_number_of_tc_parking*modeling_reduction_factor) + ") NEW TC for PARKING-AREAS";
					do create_tc (calc_number_of_tc_parking,'parking','hiking');
			}
			
			// CREATE NEW TC starting at parking-areas (2), subtype = stopover
			calc_factor_parking_stopover <- int(10000 * factor_holiday * factor_weekday * factor_season * calc_factor_weather)/10000;
			calc_number_of_tc_parking_stopover <- int(truncated_gauss({int(standard_number_of_tc_parking_stopover / modeling_reduction_factor * calc_factor_parking_stopover),int(standard_number_of_tc_parking_stopover / modeling_reduction_factor * calc_factor_parking_stopover) * calc_number_of_tc_halfrange_factor})); 
			if (FIXEDQUANTITIES) {
				calc_factor_parking_stopover <- int(10000 * factor_holiday * factor_weekday * factor_season)/10000;
				calc_number_of_tc_parking_stopover <- int(standard_number_of_tc_parking_stopover / modeling_reduction_factor * calc_factor_parking_stopover);
			}
			if (DRYRUNMODE) {calc_number_of_tc_parking_stopover <- 0;} 
			if (not BUGFIXMODE) {
					write "# [" + (date_days) + "] CREATING with factor " + calc_factor_parking_stopover with_precision 4 + " the number of " + calc_number_of_tc_parking_stopover + " (" + int(calc_number_of_tc_parking_stopover*modeling_reduction_factor) + ") NEW TC for PARKING-AREAS (STOPOVER)";
					do create_tc (calc_number_of_tc_parking_stopover,'parking','stopover');
				} else {
					write "BF# [" + (date_days) + "] CREATING with factor " + calc_factor_parking_stopover with_precision 4 + " the number of " + calc_number_of_tc_parking_stopover + " (" + int(calc_number_of_tc_parking_stopover*modeling_reduction_factor) + ") NEW TC for PARKING-AREAS (STOPOVER)";
					do create_tc (calc_number_of_tc_parking_stopover,'parking','stopover');
			}

			// CREATE NEW TC starting at bus-stops
			calc_factor_bus <- int(10000 * factor_holiday * factor_weekday * factor_season * calc_factor_weather)/10000;
			calc_number_of_tc_bus <- int(truncated_gauss({int(standard_number_of_tc_bus / modeling_reduction_factor * calc_factor_bus),int(standard_number_of_tc_bus / modeling_reduction_factor * calc_factor_bus) * calc_number_of_tc_halfrange_factor})); 
			if (FIXEDQUANTITIES) {
				calc_factor_bus <- int(10000 * factor_holiday * factor_weekday * factor_season)/10000;
				calc_number_of_tc_bus <- int(standard_number_of_tc_bus / modeling_reduction_factor * calc_factor_bus);
			}
			if (DRYRUNMODE) {calc_number_of_tc_bus <- 0;} 
			if (not BUGFIXMODE) {
					write "# [" + (date_days) + "] CREATING with factor " + calc_factor_bus with_precision 4 + " the number of " + calc_number_of_tc_bus + " (" + int(calc_number_of_tc_bus*modeling_reduction_factor) + ") NEW TC for BUS-STOPS";
					do create_tc (calc_number_of_tc_bus,'bus','hiking');
				} else {
					write "BF# [" + (date_days) + "] CREATING with factor " + calc_factor_bus with_precision 4 + " the number of " + calc_number_of_tc_bus + " (" + int(calc_number_of_tc_bus*modeling_reduction_factor) + ") NEW TC for BUS-STOPS";
					do create_tc (calc_number_of_tc_bus,'bus','hiking');
			}

			// CREATE NEW TC starting at towns
			calc_factor_town <- int(10000 * factor_holiday * factor_weekday * factor_season * calc_factor_weather)/10000;
			calc_number_of_tc_town <- int(truncated_gauss({int(standard_number_of_tc_town / modeling_reduction_factor * calc_factor_town),int(standard_number_of_tc_town / modeling_reduction_factor * calc_factor_town) * calc_number_of_tc_halfrange_factor})); 
			if (FIXEDQUANTITIES) {
				calc_factor_town <- int(10000 * factor_holiday * factor_weekday * factor_season)/10000;
				calc_number_of_tc_town <- int(standard_number_of_tc_town / modeling_reduction_factor * calc_factor_town);
			}
			if (DRYRUNMODE) {calc_number_of_tc_town <- 0;} 
			if (not BUGFIXMODE) {
					write "# [" + (date_days) + "] CREATING with factor " + calc_factor_town with_precision 4 + " the number of " + calc_number_of_tc_town + " (" + int(calc_number_of_tc_town*modeling_reduction_factor) + ") NEW TC for TOWNS";
					do create_tc (calc_number_of_tc_town,'town','hiking');
				} else {
					write "BF# [" + (date_days) + "] CREATING with factor " + calc_factor_town with_precision 4 + " the number of " + calc_number_of_tc_town + " (" + int(calc_number_of_tc_town*modeling_reduction_factor) + ") NEW TC for TOWNS";
					do create_tc (calc_number_of_tc_town,'town','hiking');
			}

			// CREATE NEW TC starting at train-stations
			calc_factor_train <- int(10000 * factor_holiday * factor_weekday * factor_season * calc_factor_weather)/10000;
			calc_number_of_tc_train <- int(truncated_gauss({int(standard_number_of_tc_train / modeling_reduction_factor * calc_factor_train),int(standard_number_of_tc_train / modeling_reduction_factor * calc_factor_train) * calc_number_of_tc_halfrange_factor})); 
			if (FIXEDQUANTITIES) {
				calc_factor_train <- int(10000 * factor_holiday * factor_weekday * factor_season)/10000;
				calc_number_of_tc_train <- int(standard_number_of_tc_train / modeling_reduction_factor * calc_factor_train);
			}
			if (DRYRUNMODE) {calc_number_of_tc_train <- 0;} 
			if (not BUGFIXMODE) {
					write "# [" + (date_days) + "] CREATING with factor " + calc_factor_train with_precision 4 + " the number of " + calc_number_of_tc_train + " (" + int(calc_number_of_tc_train*modeling_reduction_factor) + ") NEW TC for TRAIN-STATIONS";
					do create_tc (calc_number_of_tc_train,'train','hikingortrain');
				} else {
					write "BF# [" + (date_days) + "] CREATING with factor " + calc_factor_train with_precision 4 + " the number of " + calc_number_of_tc_train + " (" + int(calc_number_of_tc_train*modeling_reduction_factor) + ") NEW TC for TRAIN-STATIONS";
					do create_tc (calc_number_of_tc_train,'train','hikingortrain');
			}

			// generate several distribution and make a better x-axis if possible
			distribution_tc_members <- distribution_of(tc collect(each.tc_members),length(tc_members_weighted_list)-1,1,length(tc_members_weighted_list));
			list<string> new_legend <- [];
			list<string> legend <- (distribution_tc_members['legend']);	
			loop i over:legend { add copy_between(i,1,i index_of ".") to:new_legend; }
			distribution_tc_members['legend'] <- new_legend;

			distribution_tc_restingattarget_cycles <- distribution_of(tc collect(each.tc_restingattarget_cycles),2*tc_restingattarget_cycles_halfrange+1,tc_restingattarget_cycles_mean - tc_restingattarget_cycles_halfrange,tc_restingattarget_cycles_mean + tc_restingattarget_cycles_halfrange+1);
			new_legend <- [];
			legend <- (distribution_tc_restingattarget_cycles['legend']);	
			loop i over:legend { add copy_between(i,1,i index_of ".") to:new_legend; }
			distribution_tc_restingattarget_cycles['legend'] <- new_legend;

			distribution_tc_max_hiking_distance <- distribution_of(tc collect(each.tc_max_hiking_distance),10,int(tc_standard_hiking_distance_localized),int(tc_standard_hiking_distance + tc_standard_hiking_distance_halfrange));
			new_legend <- [];
			legend <- (distribution_tc_max_hiking_distance['legend']);	
			loop i over:legend { add replace(i,'.0','') to:new_legend; }
			distribution_tc_max_hiking_distance['legend'] <- new_legend;

			distribution_tc_startcycle <- distribution_of(tc collect(each.tc_startcycle),12,0,144);
			new_legend <- [];
			legend <- (distribution_tc_startcycle ['legend']);	
			loop i over:legend { add replace(i,'.0','') to:new_legend; }
			distribution_tc_startcycle ['legend'] <- new_legend;

	}


	// ---------------------------------------------------------------------------------------
	// global:	save a summary of some model parameters
	// ---------------------------------------------------------------------------------------
	action save_summary_of_parameters {

		// save a summary of some model parameters
		string filename <- "modelparameters.txt";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}

		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("actualdatetimestring: " + actualdatetimestring) to:file_output + filename rewrite:false type:"text";
		save ("identification: " + identification) to:file_output + filename rewrite:false type:"text";
		save ("step: " + step) to:file_output + filename rewrite:false type:"text";
		save ("date_cycles_per_simulation_day: " + date_cycles_per_simulation_day) to:file_output + filename rewrite:false type:"text";
		save ("date_cycles_per_simulation_hour: " + date_cycles_per_simulation_hour) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("BUGFIXMODE: " + BUGFIXMODE) to:file_output + filename rewrite:false type:"text";
		save ("FIXEDQUANTITIES: " + FIXEDQUANTITIES) to:file_output + filename rewrite:false type:"text";
		save ("EQUALATTRACTIONSMODE: " + EQUALATTRACTIONSMODE) to:file_output + filename rewrite:false type:"text";
		save ("EQUALWEIGHTS: " + EQUALWEIGHTS) to:file_output + filename rewrite:false type:"text";
		save ("DRYRUNMODE: " + DRYRUNMODE) to:file_output + filename rewrite:false type:"text";
		save ("ACTIVATEWINTER: " + ACTIVATEWINTER) to:file_output + filename rewrite:false type:"text";
		save ("ACTIVATESUMMER: " + ACTIVATESUMMER) to:file_output + filename rewrite:false type:"text";
		save ("ACTIVITYWINTERDAYS: " + ACTIVITYWINTERDAYS) to:file_output + filename rewrite:false type:"text";
		save ("numberofwinterdays: " + numberofwinterdays) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("shortest_path_algorithm: " + shortest_path_algorithm) to:file_output + filename rewrite:false type:"text";
		save ("simulation_year: " + simulation_year) to:file_output + filename rewrite:false type:"text";
		save ("proba_winter_period: " + proba_winter_period) to:file_output + filename rewrite:false type:"text";
		save ("winter_period_mean: " + winter_period_mean) to:file_output + filename rewrite:false type:"text";
		save ("winter_period_halfrange: " + winter_period_halfrange) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("pause_condition: " + pause_condition) to:file_output + filename rewrite:false type:"text";
		save ("pause_condition_value: " + pause_condition_value) to:file_output + filename rewrite:false type:"text";
		save ("start_simuation_at_day: " + start_simuation_at_day) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("use_actualdatetimestring: " + use_actualdatetimestring) to:file_output + filename rewrite:false type:"text";
		save ("save_periodical_files: " + save_periodical_files) to:file_output + filename rewrite:false type:"text";
		save ("save_parameter_summary (start): " + save_parameter_summary) to:file_output + filename rewrite:false type:"text";
		save ("save_values_summary (end): " + save_values_summary) to:file_output + filename rewrite:false type:"text";
		save ("save_species_summarys (end): " + save_species_summarys) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("modeling_reduction_factor: " + modeling_reduction_factor with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("standard_number_of_tc_parking: " + standard_number_of_tc_parking with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("standard_number_of_tc_parking_stopover: " + standard_number_of_tc_parking_stopover with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("standard_number_of_tc_bus: " + standard_number_of_tc_bus with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("standard_number_of_tc_train: " + standard_number_of_tc_train with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("standard_number_of_tc_town: " + standard_number_of_tc_town with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("total_standard_number_of_tc: " + total_standard_number_of_tc with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("usage_percent_category_lower: " + usage_percent_category_lower with_precision 4) to:file_output + filename rewrite:false type:"text";
		save ("usage_percent_category_upper: " + usage_percent_category_upper with_precision 4) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("tc_members_weighted_list: " + tc_members_weighted_list) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_speed: " + tc_standard_speed with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_speed_halfrange: " + tc_standard_speed_halfrange with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_hiking_distance: " + tc_standard_hiking_distance with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_hiking_distance_halfrange: " + tc_standard_hiking_distance_halfrange with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_hiking_distance_localized: " + tc_standard_hiking_distance_localized with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("tc_standard_hiking_distance_stopover: " + tc_standard_hiking_distance_stopover with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("nearbyparking_path_distance: " + nearbyparking_path_distance with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("proba_tc_by_train_getback: " + proba_tc_by_train_getback with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("calc_number_of_tc_halfrange_factor: " + calc_number_of_tc_halfrange_factor with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("tc_destinationtype_weighted_list: " + tc_destinationtype_weighted_list) to:file_output + filename rewrite:false type:"text";
		save ("tc_destinationtype_list: " + tc_destinationtype_list) to:file_output + filename rewrite:false type:"text";
		save ("tc_restingattarget_cycles_mean: " + tc_restingattarget_cycles_mean) to:file_output + filename rewrite:false type:"text";
		save ("tc_restingattarget_cycles_halfrange: " + tc_restingattarget_cycles_halfrange) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("goto_additional_targets: " + goto_additional_targets) to:file_output + filename rewrite:false type:"text";
		save ("tc_max_additional_targets: " + tc_max_additional_targets) to:file_output + filename rewrite:false type:"text";
		save ("tc_max_targets_atonce: " + tc_max_targets_atonce) to:file_output + filename rewrite:false type:"text";
		save ("tc_probability_to_add_additional_targets: " + tc_probability_to_add_additional_targets) to:file_output + filename rewrite:false type:"text";
		save ("max_additional_poi_aerial_distance: " + max_additional_poi_aerial_distance) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
		save ("weather_factor_weighted_list: " + weather_factor_weighted_list) to:file_output + filename rewrite:false type:"text";
		save ("weather_factors_list: " + weather_factors_list) to:file_output + filename rewrite:false type:"text";
		save ("factor_weather_smoothing_value: " + factor_weather_smoothing_value with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("factor_weekday_value: " + factor_weekday_value with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("factor_holiday_value: " + factor_holiday_value with_precision 2) to:file_output + filename rewrite:false type:"text";
		save ("--------------------------------------------------------------------") to:file_output + filename rewrite:false type:"text";
	}

	// ---------------------------------------------------------------------------------------
	// global:	action to activate / load the right ways according to
	// 					simulation_year and season_type
	// ---------------------------------------------------------------------------------------
	action activate_ways_and_pois (string local_simulation_year, string local_season_type) {

		// ACTIVATEWINTER
		if (ACTIVATEWINTER) {
			local_season_type <- 'winter';
		}

		// ACTIVATESUMMER (summer wins over all winter modes)
		if (ACTIVATESUMMER) {
			local_season_type <- 'summer';
		}

		// standard weight map (shape.perimeter is the normal factor = 1 weight! (makes ist faster / slower)
		// additional weights map for nature-tc
		if (EQUALWEIGHTS) {
				weights_map_summer <- ways_summer as_map(each::float(each.shape.perimeter));
				weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter)); 
				weights_map_summer_2020 <- ways_summer_2020 as_map(each::float(each.shape.perimeter));
				weights_map_summer_nature_2020 <- ways_summer_2020 as_map(each::float(each.shape.perimeter)); 
			} else {
				weights_map_summer <- ways_summer as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_summer));
				weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer)); 
				weights_map_summer_2020 <- ways_summer_2020 as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_summer));
				weights_map_summer_nature_2020 <- ways_summer_2020 as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer)); 
		}

		// standard weight map (shape.perimeter is the normal factor = 1 weight! (makes ist faster / slower)
		// additional weights map for nature-tc
		// summer and winter difficulty factor apply BOTH (!)
		if (EQUALWEIGHTS) {
				weights_map_winter <- ways_winter as_map(each::float(each.shape.perimeter)); 
				weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter));
				weights_map_winter_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter));
				weights_map_winter_nature_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter));
				if (ACTIVITYWINTERDAYS) {
					weights_map_winter <- ways_winter as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_winter)); 
					weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_winter));
					weights_map_winter_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_winter));
					weights_map_winter_nature_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_winter));
				}
			} else {
				weights_map_winter <- ways_winter as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter)); 
				weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter));
				weights_map_winter_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter));
				weights_map_winter_nature_2020 <- ways_winter_2020 as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter));
		}

		// create the weighted ways-graph to bind the touringcompanies on and take the right ways-list as as basis
		if (local_season_type = "summer") {
				// SUMMER:Set POI lists and ways 
				pois_primary <- pois_primary_summer;
				pois_all <- pois_all_summer;
				if (local_simulation_year = '2011') {
						// 2011 (new ways-planning started)
						ways_graph <- as_edge_graph(ways_summer) with_weights(weights_map_summer) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						ways_graph_nature <- as_edge_graph(ways_summer) with_weights(weights_map_summer_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						set_season_type <- 'summer2011';
						write "---> Season_type set to: " + set_season_type;
					} else if (local_simulation_year = '2020') {
						// 2020 all plans should have become reality  
						ways_graph <- as_edge_graph(ways_summer_2020) with_weights(weights_map_summer_2020) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						ways_graph_nature <- as_edge_graph(ways_summer_2020) with_weights(weights_map_summer_nature_2020) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						set_season_type <- 'summer2020';
						write "---> Season_type set to: " + set_season_type;
				}

			} else if (local_season_type = "winter") {
				// WINTER-PERIOD: Set POI lists and ways 
				pois_primary <- pois_primary_winter;
				pois_all <- pois_all_winter;
				if (local_simulation_year = '2011') {
						// 2011 (new ways-planning started)
						ways_graph <- as_edge_graph(ways_winter) with_weights(weights_map_winter) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						ways_graph_nature <- as_edge_graph(ways_winter) with_weights(weights_map_winter_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						set_season_type <- 'winter2011';
						write "---> Season_type set to: " + set_season_type;
					} else if (local_simulation_year = '2020') {
						// 2020 all plans should have become reality  
						ways_graph <- as_edge_graph(ways_winter_2020) with_weights(weights_map_winter_2020) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						ways_graph_nature <- as_edge_graph(ways_winter_2020) with_weights(weights_map_winter_nature_2020) with_optimizer_type(shortest_path_algorithm) use_cache(true);
						set_season_type <- 'winter2020';
						write "---> Season_type set to: " + set_season_type;
				}
		}
	}


	// ---------------------------------------------------------------------------------------
	// global:	action to recalculate the weights for ways (close-to-nature)
	// 					according to simulation_year and season_type
	// ---------------------------------------------------------------------------------------
	action recalculate_ways {
		// recalculate the weight-map for close to nature hikers
		if (set_season_type = "summer2011" or set_season_type = "summer2020") {
				// additional weights map for nature-tc
				if (simulation_year = '2011') {
						// 2017 (new ways-planning started)
						if (EQUALWEIGHTS) {
								weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter));
							} else {
								weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.usage_percent_category));
						}
						ways_graph_nature <- as_edge_graph(ways_summer) with_weights(weights_map_summer_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
					} else if (simulation_year = '2020') {
						// 2020 all plans should have become reality  
						if (EQUALWEIGHTS) {
								weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter));
							} else {
								weights_map_summer_nature <- ways_summer as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.usage_percent_category));
						}
						ways_graph_nature <- as_edge_graph(ways_summer_2020) with_weights(weights_map_summer_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
				}

			} else if (set_season_type = "winter2011" or set_season_type = "winter2020") {
				// additional weights map for nature-tc
				if (simulation_year = '2011') {
						// 2011 (new ways-planning started)
						if (EQUALWEIGHTS) {
								weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter));
							} else {
								weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter * each.usage_percent_category));
						}
						ways_graph_nature <- as_edge_graph(ways_winter) with_weights(weights_map_winter_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
					} else if (simulation_year = '2020') {
						// 2020 all plans should have become reality  
						if (EQUALWEIGHTS) {
								weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter));
							} else {
								weights_map_winter_nature <- ways_winter as_map(each::float(each.shape.perimeter * each.shape_way_nature * each.shape_way_category * each.way_difficulty_factor_summer * each.way_difficulty_factor_winter * each.usage_percent_category));
						}
						ways_graph_nature <- as_edge_graph(ways_winter) with_weights(weights_map_winter_nature) with_optimizer_type(shortest_path_algorithm) use_cache(true);
				}
		}
	}


	// ---------------------------------------------------------------------------------------
	// global: action to create the touringcompanys
	// ---------------------------------------------------------------------------------------
	action create_tc (int local_calc_number_of_tc, string local_starting_locations, string local_location_subtype) {

		// create the tc
		create tc number: local_calc_number_of_tc {
			// set the status of the tc
			tc_status <- 'setup';

			// get a well written ID (only digits) from the automatically created one
			tc_id <- int(self);

			// the tc is actually located "nowhere" = invisible!
			location <- point(0,0);

			// set number of members per touringcompany (+1 for index starting at 0!!!)
			if (not BUGFIXMODE) {
					tc_members <- 1 + int(get_random_value_of_weighted_list (tc_members_weighted_list));
				} else {
					tc_members <- 1 + int(get_random_value_of_weighted_list (tc_members_weighted_list));
			}

			// set the individual hiking speed (speed is the standard variable for this!)
			if (not BUGFIXMODE) {
					speed <- truncated_gauss({tc_standard_speed,tc_standard_speed_halfrange}) * weather_hikingspeed_today_factor;
				} else {
					speed <- truncated_gauss({tc_standard_speed,tc_standard_speed_halfrange}) * weather_hikingspeed_today_factor;
			}
			
			// set (and count) the individual destination type (the "interests" of this tc)
			if (not BUGFIXMODE) {
					// if this a tc of type 'stopover', set the destinationatype to 'target', all other are random
					if (local_location_subtype = 'stopover') {
							tc_destinationtype <- 'target';
						} else {
							tc_destinationtype <- tc_destinationtype_list[int(get_random_value_of_weighted_list (tc_destinationtype_weighted_list))];
					}
				} else {
					if (local_location_subtype = 'stopover') {
							tc_destinationtype <- 'target';
						} else {
							tc_destinationtype <- tc_destinationtype_list[int(get_random_value_of_weighted_list (tc_destinationtype_weighted_list))];
					}
			}
			if (tc_destinationtype = 'target') {
					total_tc_desttype_target <- total_tc_desttype_target + 1;
					total_tc_mb_desttype_target <- total_tc_mb_desttype_target + tc_members;  
				} else if (tc_destinationtype = 'nature') {
					total_tc_desttype_nature <- total_tc_desttype_nature + 1;
					total_tc_mb_desttype_nature <- total_tc_mb_desttype_nature + tc_members;  
				} else if (tc_destinationtype = 'hwn') {
					total_tc_desttype_hwn <- total_tc_desttype_hwn + 1;
					total_tc_mb_desttype_hwn <- total_tc_mb_desttype_hwn + tc_members;  
			} 

			// number of cycles this tc will rest at a target (standard)
			if (not BUGFIXMODE) {
					tc_restingattarget_cycles <- int(truncated_gauss({tc_restingattarget_cycles_mean,tc_restingattarget_cycles_halfrange}));
				} else {
					tc_restingattarget_cycles <- int(truncated_gauss({tc_restingattarget_cycles_mean,tc_restingattarget_cycles_halfrange}));
			}
			
			// set the starting cycle (time)
			if (not BUGFIXMODE) {
					// if this a tc of type 'stopover', set the startcycle more to the "middle", all other are standard/random
					if (local_location_subtype = 'stopover') {
							tc_startcycle <- int(truncated_gauss({tc_startcycle_mean_stopover,tc_startcycle_halfrange_stopover}));
						} else {
							tc_startcycle <- int(truncated_gauss({tc_startcycle_mean,tc_startcycle_halfrange}));
					}
				} else {
					// if this a tc of type 'stopover', set the startcycle more to the "middle", all other are standard/random
					if (local_location_subtype = 'stopover') {
							tc_startcycle <- int(truncated_gauss({tc_startcycle_mean_stopover,tc_startcycle_halfrange_stopover}));
						} else {
							tc_startcycle <- int(truncated_gauss({tc_startcycle_mean,tc_startcycle_halfrange}));
					}
			}

			// P A R K I N G (1) "hiking"
			// get the start parking area ("home") of the tc, keep in mind the maximum capacity of the parking areas
			// and don't choose any starting points where the attraction is 0!
			if (local_starting_locations = 'parking' and local_location_subtype = 'hiking') {
				tc_starttype <- 'parking';
				list<parking> possibleparkingareas <- parking where	(	each.shape_capacity / modeling_reduction_factor > each.tc_home_now
																															and each.shape_attraction != 0
																														);
				if (length(possibleparkingareas) = 0) {
						// no much space left at any parking area, abort the creation of this tc
						tc_status <- 'nospace';

						// making up the total counts
						total_tc_nospace <- total_tc_nospace + 1;
						total_tc_mb_nospace <- total_tc_mb_nospace + tc_members;

					} else {
						// found some space at one of the parking areas, create this tc
						list<int> parking_weighted_list <- possibleparkingareas collect each.shape_attraction;
						int random_weighted_parking <- int(get_random_value_of_weighted_list (parking_weighted_list));
			
						// set the individual maximum hiking distance
						tc_max_hiking_distance <- truncated_gauss({tc_standard_hiking_distance,tc_standard_hiking_distance_halfrange});

						// set this parking area as the "home"
						point tc_target <- point(possibleparkingareas[random_weighted_parking]);
						add tc_target to:list_tc_target_points;
						add tc_target to:list_tc_total_target_points;
						
						// count tc at their homes = parking-areas
						ask parking(first(list_tc_target_points)) {
							sum_tc_home <- sum_tc_home + 1;
							sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
						}
						
						// making up the total counts
						total_tc_parking <- total_tc_parking + 1;
						total_tc_mb_parking <- total_tc_mb_parking + tc_members;
				}

			// P A R K I N G (2) "stopover"
			// get the start parking area ("home") of the tc, keep in mind the maximum capacity of the parking areas
			// and don't choose any starting points where the attraction_stopover is 0!
			} else if (local_starting_locations = 'parking' and local_location_subtype = 'stopover') {
				tc_starttype <- 'parking';
				list<parking> possibleparkingareas <- parking where	(	each.shape_capacity / modeling_reduction_factor > each.tc_home_now
																															and each.shape_attraction_stopover != 0
																														);
				if (length(possibleparkingareas) = 0) {
						// no much space left at any parking area, abort the creation of this tc
						tc_status <- 'nospace';

						// making up the total counts
						total_tc_nospace <- total_tc_nospace + 1;
						total_tc_mb_nospace <- total_tc_mb_nospace + tc_members;

					} else {
						// found some space at one of the parking areas, create this tc
						list<int> parking_weighted_list <- possibleparkingareas collect each.shape_attraction_stopover;
						int random_weighted_parking <- int(get_random_value_of_weighted_list (parking_weighted_list));
			
						// set the individual maximum hiking distance
						tc_max_hiking_distance <- tc_standard_hiking_distance_stopover;

						// set this parking area as the "home"
						point tc_target <- point(possibleparkingareas[random_weighted_parking]);
						add tc_target to:list_tc_target_points;
						add tc_target to:list_tc_total_target_points;
						
						// count tc at their homes = parking-areas
						ask parking(first(list_tc_target_points)) {
							sum_tc_home <- sum_tc_home + 1;
							sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
						}
						
						// making up the total counts
						total_tc_parking <- total_tc_parking + 1;
						total_tc_mb_parking <- total_tc_mb_parking + tc_members;
				}

			// B U S
			} else if (local_starting_locations = 'bus' and local_location_subtype = 'hiking') {
				tc_starttype <- 'bus';
				list<bus> possiblebusstops <- list(bus where(each.shape_attraction != 0));
				list<int> bus_weighted_list <- possiblebusstops collect each.shape_attraction;
				int random_weighted_bus <- int(get_random_value_of_weighted_list (bus_weighted_list));

				// set the individual maximum hiking distance
				tc_max_hiking_distance <- truncated_gauss({tc_standard_hiking_distance,tc_standard_hiking_distance_halfrange});

				// set this bus-stop as the "home"
				point tc_target <- point(possiblebusstops[random_weighted_bus]);
				add tc_target to:list_tc_target_points;
				add tc_target to:list_tc_total_target_points;

				// count tc at their homes = bus-stop
				ask bus(first(list_tc_target_points)) {
					sum_tc_home <- sum_tc_home + 1;
					sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
				}

				// making up the total counts
				total_tc_bus <- total_tc_bus + 1;
				total_tc_mb_bus <- total_tc_mb_bus + tc_members;

			// T O W N
			} else if (local_starting_locations = 'town' and local_location_subtype = 'hiking') {
				tc_starttype <- 'town';
				list<towns> possibletowns <- list(towns where(each.shape_attraction != 0));
				list<int> towns_weighted_list <- possibletowns collect each.shape_attraction;
				int random_weighted_towns <- int(get_random_value_of_weighted_list (towns_weighted_list));

				// set the individual maximum hiking distance
				tc_max_hiking_distance <- truncated_gauss({tc_standard_hiking_distance,tc_standard_hiking_distance_halfrange});

				// set this town as the "home"
				point tc_target <- point(possibletowns[random_weighted_towns]);
				add tc_target to:list_tc_target_points;
				add tc_target to:list_tc_total_target_points;

				// count tc at their homes = town
				ask towns(first(list_tc_target_points)) {
					sum_tc_home <- sum_tc_home + 1;
					sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
				}

				// making up the total counts
				total_tc_town <- total_tc_town + 1;
				total_tc_mb_town <- total_tc_mb_town + tc_members;

			// T R A I N
			} else if (local_starting_locations = 'train' and local_location_subtype = 'hikingortrain') {
				tc_starttype <- 'train';

				// there is only ONE train station at the Brocken, but we take the same procedure as for all starting points!
				list<train> possibletrainstops <- list(train where (each.shape_attraction != 0));
				list<int> train_weighted_list <- possibletrainstops collect each.shape_attraction;
				int random_weighted_train <- int(get_random_value_of_weighted_list (train_weighted_list));

				// set the individual maximum hiking distance
				tc_max_hiking_distance <- truncated_gauss({tc_standard_hiking_distance,tc_standard_hiking_distance_halfrange});
	
				// tc by train almost have a target in mind ("Brocken"), overwrite this value
				tc_destinationtype <- 'target';

				// set this train-stop as the "home" and the location for the tc
				// if this tc will go back by train (to the valley)
				if (flip(proba_tc_by_train_getback)) {
						// (1) train_train-branch

						// mark this tc
						tc_startsubtype <- 'bytrain_train';

						// the station (at the Brocken) is the home (tc wants to get back by train)
						point tc_target <- point(possibletrainstops[random_weighted_train]);
						add tc_target to:list_tc_target_points;
						add tc_target to:list_tc_total_target_points;
						
						// count tc at their homes = parking-areas
						ask train(first(list_tc_target_points)) {
							sum_tc_home <- sum_tc_home + 1;
							sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
						}

						// reduce the individual maximum hiking distance for nearby POIs (at the Brocken)
						tc_max_hiking_distance <- tc_standard_hiking_distance_localized;
						
						// making up the total counts
						total_tc_train_train <- total_tc_train_train + 1;
						total_tc_mb_train_train <- total_tc_mb_train_train + tc_members;
						
					} else {
						// (2) train_valley-branch

						// possible parking areas
						list<parking> possibleparking <- [];
						loop pa over:parking where(each.shape_attraction != 0 and each.shape_attraction_train != 0) {
							// parking area is in reachable distance, there was some space for the car
							// use the normal ways_graph (train is of tc_destinationtype='target'), always start at train[0]
							if (point(train[0]) distance_to pa using topology(ways_graph) <= tc_max_hiking_distance and (pa.shape_capacity / modeling_reduction_factor) > pa.tc_home_now) {
								add (pa) to: possibleparking;
							}
						}

						// possible bus-stops
						list<bus> possiblebus <- [];
						loop b over:bus where(each.shape_attraction != 0 and each.shape_attraction_train != 0) {
							// bus is in reachable distance
							// use the normal ways_graph (train is of tc_destinationtype='target'), always start at train[0]
							if (point(train[0]) distance_to b using topology(ways_graph) <= tc_max_hiking_distance) {
								add (b) to: possiblebus;
							}
						}

						// possible towns
						list<towns> possibletowns <- [];
						loop t over:towns where(each.shape_attraction != 0 and each.shape_attraction_train != 0) {
							// town is in reachable distance
							// use the normal ways_graph (train is of tc_destinationtype='target'), always start at train[0]
							if (point(train[0]) distance_to t using topology(ways_graph) <= tc_max_hiking_distance) {
								add (t) to: possibletowns;
							}
						}

						// set the target_home
						int random_targethometype <- int(get_random_value_of_weighted_list ([int(standard_number_of_tc_parking/(standard_number_of_tc_parking+standard_number_of_tc_bus+standard_number_of_tc_town)*100),int(standard_number_of_tc_bus/(standard_number_of_tc_parking+standard_number_of_tc_bus+standard_number_of_tc_town)*100),int(standard_number_of_tc_town/(standard_number_of_tc_parking+standard_number_of_tc_bus+standard_number_of_tc_town)*100)]));
						if (	length(possibleparking) != 0
									and random_targethometype = 0
								) {
								// set one of the reachable PARKING AREAS as the home
								list<int> parking_weighted_list <- possibleparking collect each.shape_attraction_train;
								int random_weighted_parking <- int(get_random_value_of_weighted_list (parking_weighted_list));

								// set this parking area as the "home"
								point tc_target <- point(possibleparking[random_weighted_parking]);
								add tc_target to:list_tc_target_points;
								add tc_target to:list_tc_total_target_points;
								
								// count tc at their homes = parking-areas
								ask parking(first(list_tc_target_points)) {
									sum_tc_home <- sum_tc_home + 1;
									sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
									sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
									sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + myself.tc_members;
								}

								// mark this tc
								tc_startsubtype <- 'bytrain_valley';

								// making up the total counts
								total_tc_train_valley <- total_tc_train_valley + 1;
								total_tc_mb_train_valley <- total_tc_mb_train_valley + tc_members;
								
							} else if (length(possiblebus) != 0
									and random_targethometype = 1
								) {
								// set one of the reachable BUS-STOPS as the home
								list<int> bus_weighted_list <- possiblebus collect each.shape_attraction_train;
								int random_weighted_bus <- int(get_random_value_of_weighted_list (bus_weighted_list));

								// set this bus-stopas the "home"
								point tc_target <- point(possiblebus[random_weighted_bus]);
								add tc_target to:list_tc_target_points;
								add tc_target to:list_tc_total_target_points;
								
								// count tc at their homes = parking-areas
								ask bus(first(list_tc_target_points)) {
									sum_tc_home <- sum_tc_home + 1;
									sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
									sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
									sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + myself.tc_members;
								}

								// mark this tc
								tc_startsubtype <- 'bytrain_valley';

								// making up the total counts
								total_tc_train_valley <- total_tc_train_valley + 1;
								total_tc_mb_train_valley <- total_tc_mb_train_valley + tc_members;

							} else if (length(possibletowns) != 0
								and random_targethometype = 2
							) {
								// set one of the reachable TOWNS as the home
								list<int> towns_weighted_list <- possibletowns collect each.shape_attraction_train;
								int random_weighted_towns <- int(get_random_value_of_weighted_list (towns_weighted_list));

								// set this town as the "home"
								point tc_target <- point(possibletowns[random_weighted_towns]);
								add tc_target to:list_tc_target_points;
								add tc_target to:list_tc_total_target_points;
								
								// count tc at their homes = parking-areas
								ask towns(first(list_tc_target_points)) {
									sum_tc_home <- sum_tc_home + 1;
									sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
									sum_tc_BROCKEN <- sum_tc_BROCKEN + 1;
									sum_tc_members_BROCKEN <- sum_tc_members_BROCKEN + myself.tc_members;
								}

								// mark this tc
								tc_startsubtype <- 'bytrain_valley';

								// making up the total counts
								total_tc_train_valley <- total_tc_train_valley + 1;
								total_tc_mb_train_valley <- total_tc_mb_train_valley + tc_members;

							} else {
								// the station (at the Brocken) is the home, tc has no reachable PARKING/BUS/TOWN
								point tc_target <- point(possibletrainstops[random_weighted_train]);
								add tc_target to:list_tc_target_points;
								add tc_target to:list_tc_total_target_points;
								
								// count tc at their homes = train
								ask train(first(list_tc_target_points)) {
									sum_tc_home <- sum_tc_home + 1;
									sum_tc_members_home <- sum_tc_members_home + myself.tc_members; 
								}

								// mark this tc
								tc_startsubtype <- 'bytrain_train';

								// making up the total counts
								total_tc_train_train <- total_tc_train_train + 1;
								total_tc_mb_train_train <- total_tc_mb_train_train + tc_members;

						}

				} // END train_train or train_valley (flip)

				// ... and of course all train passengers want to visit the Brocken
				// so add the Brocken at least as a secondary target POI to the target list
				point tc_target <- point(pois[45]); // 45 = Brocken viewpoint
				add tc_target to:list_tc_target_points;
				add tc_target to:list_tc_total_target_points;
	
			} // END P|BUS|TOWN|TRAIN

		} // END create

		// make a note for missing space at the parking areas
		if (local_starting_locations = 'parking' and tc count(each.tc_status = 'nospace') > 0) {
			write "### NO MORE SPACE at any parkingarea for " + tc count(each.tc_status = 'nospace') + " tc";
		}
	}


	// ---------------------------------------------------------------------------------------
	// global: print some important model- and simulation parameters and values during runtime
	// ---------------------------------------------------------------------------------------
	action print_summary {
		write ""; 
		write "=======================================================================================================";
		write "Summary of some important actual model and simulation values (runtime):";
		write "-------------------------------------------------------------------------------------------------------";
		write "Cycle: " + cycle; 
		write "Time [s]: " + (time - step); 
		write "Simulation date (calculated): " + date_calculated; 
		write "Years infos (CSV): " + years_infos_infostring; 
		write "-------------------------------------------------------------------------------------------------------";
		write "Standard-number of tc parking (pcs) -> " + standard_number_of_tc_parking;
		write "Standard-number of tc parking-stopover (pcs) -> " + standard_number_of_tc_parking_stopover;
		write "Standard-number of tc bus (pcs) -> " + standard_number_of_tc_bus;
		write "Standard-number of tc train (pcs) -> " + standard_number_of_tc_train;
		write "Standard-number of tc town (pcs) -> " + standard_number_of_tc_town;
		write "Modeling reduction factor (1) -> " + modeling_reduction_factor;
		write "number of tc from parking (pcs) -> " + calc_number_of_tc_parking;
		write "number of tc from bus (pcs) -> " + calc_number_of_tc_bus;
		write "number of tc from town (pcs) -> " + calc_number_of_tc_town;
		write "number of tc from train (pcs) -> " + calc_number_of_tc_train;
		write "Total members of tc (pcs) -> " + sum(list_tc_members);
		write "Speed of tc (m/s) -> " + tc_standard_speed;
		write "halfrange Speed of tc (m/s) -> " + tc_standard_speed_halfrange;
		write "Speed of tc (km/h) -> " + tc_standard_speed*3.6;
		write "halfrange Speed of tc (km/h) -> " + tc_standard_speed_halfrange*3.6;
		write "Max hiking distcance of tc (m/s) -> " + tc_standard_hiking_distance;
		write "halfrange Max hiking distcance of tc (m/s) -> " + tc_standard_hiking_distance_halfrange;
		write "Mean of resting at target [cycles] -> " + tc_restingattarget_cycles_mean;
		write "halfrange of resting at target [cycles] -> " + tc_restingattarget_cycles_halfrange;
		write "Mean of startcycles [cycles] -> " + tc_startcycle_mean;
		write "halfrange of startcycles [cycles] -> " + tc_startcycle_halfrange;
		write "Mean of startcycles stopover [cycles] -> " + tc_startcycle_mean_stopover;
		write "halfrange of startcycles stopover [cycles] -> " + tc_startcycle_halfrange_stopover;
		write "Value of lastlightcles [cycles] -> " + tc_lastlightcycle;
		write "-------------------------------------------------------------------------------------------------------";
		write "tc status = notarget: " + tc count(each.tc_status = 'notarget'); 
		write "tc status = nospace: " + tc count(each.tc_status = 'nospacce'); 
		write "tc status = setup: " + tc count(each.tc_status = 'setup'); 
		write "tc status = hikingtarget: " + tc count(each.tc_status = 'hikingtarget'); 
		write "tc status = target: " + tc count(each.tc_status = 'target'); 
		write "tc status = hikinghome: " + tc count(each.tc_status = 'hikinghome'); 
		write "tc status = home: " + tc count(each.tc_status = 'home'); 
		write "-------------------------------------------------------------------------------------------------------";
		write "Hiked disctance (m): min=" + min(list_tc_hiked_distance) with_precision 4 + ", max=" + max(list_tc_hiked_distance) with_precision 4 + ", mean=" + mean(list_tc_hiked_distance) with_precision 4 + ", stddev=" + standard_deviation(list_tc_hiked_distance) with_precision 4;
		write "Hiking speed (m/s): min=" + min(list_tc_standard_speed) with_precision 4 + ", max=" + max(list_tc_standard_speed) with_precision 4 + ", mean=" + mean(list_tc_standard_speed) with_precision 4 + ", stddev=" + standard_deviation(list_tc_standard_speed) with_precision 4;
		write "-------------------------------------------------------------------------------------------------------";
		write "Ways percent usage: min=" + min(list_ways_usage_percent) with_precision 4 + ", max=" + max(list_ways_usage_percent) with_precision 4 + ", mean=" + mean(list_ways_usage_percent) with_precision 4 + ", stddev=" + standard_deviation(list_ways_usage_percent) with_precision 4;
		write "Ways percent usage category: min=" + min(list_ways_usage_percent_category) with_precision 4 + ", max=" + max(list_ways_usage_percent_category) with_precision 4 + ", mean=" + mean(list_ways_usage_percent_category) with_precision 4 + ", stddev=" + standard_deviation(list_ways_usage_percent_category) with_precision 4;
		write "-------------------------------------------------------------------------------------------------------";
		write "list_tc_members"; write list_tc_members; write "";
		write "list_tc_max_hiking_distance"; write list_tc_max_hiking_distance; write "";
		write "list_tc_destinationtype"; write list_tc_destinationtype; write "";
		write "list_tc_startcycle"; write list_tc_startcycle; write "";
		write "list_tc_restingattarget_cycles"; write list_tc_restingattarget_cycles; write "";
		write "distribution_tc_members"; write distribution_tc_members; write "";
		write "distribution_tc_max_hiking_distance"; write distribution_tc_max_hiking_distance; write "";
		write "distribution_tc_startcycle"; write distribution_tc_startcycle; write "";
		write "distribution_tc_restingattarget_cycles"; write distribution_tc_restingattarget_cycles; write "";
		write "=======================================================================================================";
		write ""; 
	}


	// ---------------------------------------------------------------------------------------
	// global: save all information (species) as shape- and text-files
	// ---------------------------------------------------------------------------------------
	action save_species_summarys {

		// save shapefile of WAYS
		string filename <- "ways-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (ways) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_wayid::"WAYID",
			shape_name::"WAYNAME",
			sum_tc_on_way::"SUM_TCON",
			avg_tc_on_way::"AVG_TCON",
			max_tc_on_way::"MAX_TCON",
			sum_tc_used_way::"SUM_TCUSED",
			count_tc_hiked_way::"C_TCHIKED",
			count_tc_members_hiked_way::"C_MBHIKED",
			count_tc_nature_hiked_way::"C_TCNATHIK",
			count_tc_members_nature_hiked_way::"C_MBNATHIK",
			count_tc_BROCKEN_hiked_way::"C_TCBROHIK",
			count_tc_members_BROCKEN_hiked_way::"C_MBBROHIK",
			usage_percent::"P_USAGE",
			way_difficulty_factor_summer::"diff_sum",
			way_difficulty_factor_winter::"diff_win"
		];

		// save shapefile of PARKING
		filename <- "parking-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (parking) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			sum_tc_home::"TCHOME",
			sum_tc_members_home::"MBHOME",
			sum_tc_BROCKEN::"TCBROCKEN",
			sum_tc_members_BROCKEN::"MBBROCKEN"
		];

		// save shapefile of BUS
		filename <- "bus-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (bus) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			sum_tc_home::"TCHOME",
			sum_tc_members_home::"MBHOME",
			sum_tc_BROCKEN::"TCBROCKEN",
			sum_tc_members_BROCKEN::"MBBROCKEN"
		];

		// save shapefile of TOWN
		filename <- "towns-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (towns) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			sum_tc_home::"TCHOME",
			sum_tc_members_home::"MBHOME",
			sum_tc_BROCKEN::"TCBROCKEN",
			sum_tc_members_BROCKEN::"MBBROCKEN"
		];

		// save shapefile of TRAIN
		filename <- "train-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (train) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			sum_tc_home::"TCHOME",
			sum_tc_members_home::"MBHOME"
		];

		// save shapefile of POIS 
		filename <- "pois-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (pois) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			shape_name::"NAME",
			tc_at_target::"TCTARGET",
			tc_members_at_target::"MBTARGET",
			tc_nature_at_target::"TCNATTARG",
			tc_members_nature_at_target::"MBNATTARG",
			tc_BROCKEN_at_target::"TCBROCTARG",
			tc_members_BROCKEN_at_target::"MBBROCTARG"
		];

		// save shapefile of COUNTINGSAREAS (CA) 
		filename <- "ca-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (ca) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			shape_name::"NAME",
			shape_type::"TYPE",
			sum_tc_in_area::"SUM_TCIN",
			sum_tc_members_in_area::"SUM_MBIN",
			count_tc_hiked_area::"C_TCHIKED",
			count_tc_members_hiked_area::"C_MBHIKED",
			count_tc_hiked_area_once::"C_TCHIKED1",
			count_tc_members_hiked_area_once::"C_MBHIKED1",
			percentage_mb_area::"P_MBHIKED"
		];

		// save shapefile of COUNTINGSPOINTS (CP)
		filename <- "cp-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (cp) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_objectid::"OBJECTID",
			shape_id::"ID",
			shape_name::"NAME",
			shape_cp::"CPNUMBER",
			shape_subpoint::"CPSUBPOINT",
			shape_direction::"CPDIRECTIO",
			sum_tc_at_cp::"SUM_TCAT",
			sum_tc_heading_dir1::"SUM_TCDIR1",
			sum_tc_heading_dir2::"SUM_TCDIR2",
			sum_tc_members_at_cp::"SUM_MBAT",
			sum_tc_members_heading_dir1::"SUM_MBDIR1",
			sum_tc_members_heading_dir2::"SUM_MBDIR2"
		];

		// save shapefile of HEATMAP 
		filename <- "heatmap-summary-end.shp";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save (heatmap) to:file_output + filename rewrite:true type:"shp" crs:"EPSG :31476" with:[
			shape_id::"ID",
			sum_tc_in_heatmap::"SUM_TCIN",
			sum_tc_members_in_heatmap::"SUM_MBIN",
			count_tc_hiked_heatmap::"C_TCHIKED",
			count_tc_members_hiked_heatmap::"C_MBHIKED",
			percentage_mb_heatmap::"P_MBHIKED"
		];


		// save CSV-file (with header) summary of WAYS
		filename <- "ways-summary-end.csv";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save ("cycle,shape_objectid,shape_wayid,tc_on_way,sum_tc_on_way,avg_tc_on_way,max_tc_on_way,sum_tc_used_way,count_tc_hiked_way,count_tc_members_hiked_way,count_tc_nature_hiked_way,count_tc_members_nature_hiked_way,count_tc_BROCKEN_hiked_way,count_tc_members_BROCKEN_hiked_way")
			to:file_output + filename rewrite:false type:"text";
		ask ways {
			save [ 	cycle,																				shape_objectid,															shape_wayid,
							tc_on_way with_precision 2,										sum_tc_on_way with_precision 2,							avg_tc_on_way with_precision 2,
							max_tc_on_way with_precision 2,								sum_tc_used_way with_precision 2,						count_tc_hiked_way with_precision 2,
							count_tc_members_hiked_way with_precision 2,	count_tc_nature_hiked_way with_precision 2,	count_tc_members_nature_hiked_way,
							count_tc_BROCKEN_hiked_way with_precision 2,	count_tc_members_BROCKEN_hiked_way with_precision 2
			] to:file_output + filename rewrite:false type:"csv";
		}

		// save CSV-file (with header) summary of POI
		filename <- "pois-summary-end.csv";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save ("cycle,shape_objectid,shape_id,shape_name,tc_at_target,tc_members_at_target,tc_nature_at_target,tc_members_nature_at_target,tc_BROCKEN_at_target,tc_members_BROCKEN_at_target")
			to:file_output + filename rewrite:false type:"text";
		ask pois {
			save [ 	cycle,																					shape_objectid,																	shape_id,
							shape_name,																			tc_at_target with_precision 2,									tc_members_at_target with_precision 2,
							tc_nature_at_target with_precision 2,						tc_members_nature_at_target with_precision 2,		tc_BROCKEN_at_target with_precision 2,
							tc_members_BROCKEN_at_target with_precision 2
			] to:file_output + filename rewrite:false type:"csv";
		}

		// save CSV-file (with header) summary of HEATMAP
		filename <- "heatmap-summary-end.csv";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save ("cycle,shape_objectid,sum_tc_in_heatmap,sum_tc_members_in_heatmap,count_tc_hiked_heatmap,count_tc_members_hiked_heatmap,percentage_mb_heatmap")
			to:file_output + filename rewrite:false type:"text";
		ask heatmap {
			save [ 	cycle,																						shape_id,
							sum_tc_in_heatmap with_precision 2,								sum_tc_members_in_heatmap with_precision 2,			count_tc_hiked_heatmap with_precision 2,
							count_tc_members_hiked_heatmap with_precision 2,	percentage_mb_heatmap with_precision 2
			] to:file_output + filename rewrite:false type:"csv";
		}

		// save CSV-file (with header) summary of PARKING
		filename <- "parking-summary-end.csv";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		save ("cycle,shape_objectid,shape_id,sum_tc_home,sum_tc_members_home,sum_tc_BROCKEN,sum_tc_members_BROCKEN")
			to:file_output + filename rewrite:false type:"text";
		ask parking {
			save [ 	cycle,																			shape_objectid, 													shape_id,
							sum_tc_home with_precision 2,								sum_tc_members_home with_precision 2,			sum_tc_BROCKEN with_precision 2,
							sum_tc_members_BROCKEN with_precision 2
			] to:file_output + filename rewrite:false type:"csv";
		}

	}


	// ---------------------------------------------------------------------------------------
	// global: save a summary of all important values as a CSV file at the end of the simulation
	// ---------------------------------------------------------------------------------------
	action save_summary_of_values_CSV {
		string filename <- "modelvalues-end.csv";
		if (use_actualdatetimestring) {filename <- actualdatetimestring + filename;}
		
		save (";actualdatetimestring;" + actualdatetimestring) to:file_output + filename rewrite:false type:"text";
		save (";identification;" + identification) to:file_output + filename rewrite:false type:"text";
		save (";execution_time;" + int((machine_time - t0)/1000)) to:file_output + filename rewrite:false type:"text";
		save (";execution_time_per_tc; " + (int((machine_time - t0)/1000/tc_total*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";modeling_reduction_factor;" + (int(10000*modeling_reduction_factor)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";;") to:file_output + filename rewrite:false type:"text";
		save (";BUGFIXMODE;" + BUGFIXMODE) to:file_output + filename rewrite:false type:"text";
		save (";FIXEDQUANTITIES;" + FIXEDQUANTITIES) to:file_output + filename rewrite:false type:"text";
		save (";EQUALATTRACTIONSMODE;" + EQUALATTRACTIONSMODE) to:file_output + filename rewrite:false type:"text";
		save (";EQUALWEIGHTS;" + EQUALWEIGHTS) to:file_output + filename rewrite:false type:"text";
		save (";DRYRUNMODE;" + DRYRUNMODE) to:file_output + filename rewrite:false type:"text";
		save (";ACTIVATEWINTER;" + ACTIVATEWINTER) to:file_output + filename rewrite:false type:"text";
		save (";ACTIVATESUMMER;" + ACTIVATESUMMER) to:file_output + filename rewrite:false type:"text";
		save (";ACTIVITYWINTERDAYS;" + ACTIVITYWINTERDAYS) to:file_output + filename rewrite:false type:"text";
		save (";numberofwinterdays;" + numberofwinterdays) to:file_output + filename rewrite:false type:"text";
		save (";;") to:file_output + filename rewrite:false type:"text";
		save ("01;mb_total_nlp_inside;" + (int(mb_total_nlp*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("02;mb_total_nlp_outside;" + (int(mb_total_outside*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("03;Brocken_train_mb_up;" + (int((total_tc_mb_train_train+total_tc_mb_train_valley)*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("04;Brocken_train_mb_down;" + (int(total_tc_mb_train_train*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("05;Brocken_hiking_mb_cp_dir1;" + (int((cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("06;Brocken_factor_mb_train_hiking_cp_dir1;" + (int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000)) to:file_output + filename rewrite:false type:"text";
		save ("07;factor_mb_bus_parking;" + (int(10000*total_tc_mb_bus/total_tc_mb_parking)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("08;factor_mb_town_parking; " + (int(10000*total_tc_mb_town/total_tc_mb_parking)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("09;total_winter_days;" + total_winter_days) to:file_output + filename rewrite:false type:"text";
		save ("10;total_tc_mb_late;" + (total_tc_mb_late*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save ("11;total_tc_mb_distancebudget;" + (total_tc_mb_distancebudget*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save ("12;avg_mb_tc;" + (int(mb_total/tc_total*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Brocken_hiking_mb_ca;" + (int((ca[0].count_tc_members_hiked_area-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";

		save (";;") to:file_output + filename rewrite:false type:"text";
		save ("20;Brocken_mb_cp_dir1;" + (int(cp[20].sum_tc_members_heading_dir1*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("21;Torfhaus_mb_2cp_dir1;" + (int((cp[24].sum_tc_members_heading_dir1+cp[26].sum_tc_members_heading_dir1)*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("22;DreiAnnenHohne_mb_cp_dir1;" + (int(cp[22].sum_tc_members_heading_dir1*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("23;Rabenklippe_mb_cp_dir1_dir2;" + (int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("24;Scharfenstein_mb_cp_dir1;" + (int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("25;Zantierplatz_mb_cp_dir1;" + (int(cp[10].sum_tc_members_heading_dir1*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("26;Bwpf_mb_POI;" + (int(pois[79].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("27;Brocken_NLP_factor_mb_cp_dir1;" + (int(int(cp[20].sum_tc_members_heading_dir1)/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("28;Torfhaus_NLP_factor_mb_2cp_dir1;" + (int(((cp[24].sum_tc_members_heading_dir1+cp[26].sum_tc_members_heading_dir1))/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("29;DreiAnnenHohne_NLP_factor_mb_cp_dir1;" + (int(cp[22].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("30;Rabenklippe_NLP_factor_mb_cp_dir1_dir2;" + (int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("31;Scharfenstein_NLP_factor_mb_cp_dir1;" + (int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("32;Zantierplatz_NLP_factor_mb_cp_dir1;" + (int(cp[10].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Brocken_mb_ca;" + (int(ca[0].count_tc_members_hiked_area*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save (";Torfhaus_mb_ca;" + (int(ca[12].count_tc_members_hiked_area*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save (";Rabenklippe_mb_ca;" + (int(ca[3].count_tc_members_hiked_area*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save (";Scharfenstein_mb_ca;" + (int(ca[2].count_tc_members_hiked_area*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save (";Bwpf_NLP_mb_POI; " + (int(pois[79].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Brocken_NLP_factor_mb_ca;" + (int(ca[0].count_tc_members_hiked_area/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Torfhaus_NLP_factor_mb_ca;" + (int(ca[12].count_tc_members_hiked_area/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Rabenklippe_NLP_factor_mb_ca;" + (int(ca[3].count_tc_members_hiked_area/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Scharfenstein_NLP_factor_mb_ca;" + (int(ca[2].count_tc_members_hiked_area/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";

		save (";;") to:file_output + filename rewrite:false type:"text";
		save ("40;Luchsgehege_mb_POI;" + (int(pois[65].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("41;Brockengarten_mb_POI;" + (int(pois[66].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("42;NLPBrocken_mb_POI;" + (int(pois[63].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("43;NLPTorfhaus_mb_POI;" + (int(pois[58].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("44;NLPHohnehof_mb_POI;" + (int(pois[64].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("45;NLPIlsetal_mb_POI;" + (int(pois[60].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("46;NLPSchierke_mb_POI;" + (int(pois[62].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("47;NLPBadHarzburg_mb_POI;" + (int(pois[56].tc_members_at_target*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save ("48;NLPScharfenstein_mb_POI;" + (int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)*modeling_reduction_factor))) to:file_output + filename rewrite:false type:"text";
		save (";Luchsgehege_NLP_mb_POI;" + (int(pois[65].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";Brockengarten_NLP_mb_POI;" + (int(pois[66].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPBrocken_NLP_mb_POI;" + (int(pois[63].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPTorfhaus_NLP_mb_POI;" + (int(pois[58].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 )) to:file_output + filename rewrite:false type:"text";
		save (";NLPHohnehof_NLP_mb_POI;" + (int(pois[64].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPIlsetal_NLP_mb_POI;" + (int(pois[60].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPSchierke_NLP_mb_POI;" + (int(pois[62].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPBadHarzburg_NLP_mb_POI;" + (int(pois[56].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save (";NLPScharfenstein_NLP_mb_POI;" + (int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000)) to:file_output + filename rewrite:false type:"text";

		save (";;") to:file_output + filename rewrite:false type:"text";
		if ((cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp) > 0) {
				save ("60;CP1_Goetheweg_mb_percent_at_cp;" + int(cp[0].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
				save ("61;CP2_StrMitte_members_percent_at_cp;" + int(cp[1].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
			} else {
				save ("60;CP1_Goetheweg_mb_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
				save ("61;CP2_StrMitte_members_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
		}

		if ((cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp) > 0) {
				save ("62;CP3_Hirtenstieg_members_percent_at_cp;" + int(cp[2].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
				save ("63;CP4_StrOben_members_percent_at_cp;" + int(cp[3].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
			} else {
				save ("62;CP3_Hirtenstieg_members_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
				save ("63;CP4_StrOben_members_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
		}

		if ((cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp) > 0) {
				save ("64;CP15_Eckerloch_members_percent_at_cp;" + int(cp[28].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
				save ("65;CP16_StrUnten_members_percent_at_cp;" + int(cp[30].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000) to:file_output + filename rewrite:false type:"text";
			} else {
				save ("64;CP15_Eckerloch_members_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
				save ("65;CP16_StrUnten_members_percent_at_cp;0") to:file_output + filename rewrite:false type:"text";
		}

		save (";;") to:file_output + filename rewrite:false type:"text";
		save ("80;count_brocken_mb_percent_BADHARZBURG;" + (int(count_brocken_members_percent_BADHARZBURG*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("81;count_brocken_mb_percent_TORFHAUS;" + (int(count_brocken_members_percent_TORFHAUS*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("82;count_brocken_mb_percent_ODERBRUECK;" + (int(count_brocken_members_percent_ODERBRUECK*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("83;count_brocken_mb_percent_BRAUNLAGE;" + (int(count_brocken_members_percent_BRAUNLAGE*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("84;count_brocken_mb_percent_SCHIERKE;" + (int(count_brocken_members_percent_SCHIERKE*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("85;count_brocken_mb_percent_DREIANNENHOHNE;" + (int(count_brocken_members_percent_DREIANNENHOHNE*10000)/10000)) to:file_output + filename rewrite:false type:"text";
		save ("86;count_brocken_mb_percent_ILSENBURG;" + (int(count_brocken_members_percent_ILSENBURG*10000)/10000)) to:file_output + filename rewrite:false type:"text";

		save (";;") to:file_output + filename rewrite:false type:"text";
		save (";total_tc;" + (tc_total_last*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_parking;" + (total_tc_parking*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_bus;" + (total_tc_bus*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_town;" + (total_tc_town*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_train_train;" + (total_tc_train_train*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_train_valley;" + (total_tc_train_valley*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_nospace;" + (total_tc_nospace*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_notarget; " + (total_tc_notarget*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_late;" + (total_tc_late*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_distancebudget;" + (total_tc_distancebudget*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_desttype_target;" + (total_tc_desttype_target*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_desttype_nature;" + (total_tc_desttype_nature*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_desttype_hwn;" + (total_tc_desttype_hwn*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb;" + (mb_total_last*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_parking;" + (total_tc_mb_parking*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_bus;" + (total_tc_mb_bus*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_town;" + (total_tc_mb_town*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_train_train;" + (total_tc_mb_train_train*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_train_valley;" + (total_tc_mb_train_valley*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_nospace;" + (total_tc_mb_nospace*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_notarget;" + (total_tc_mb_notarget*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_late;" + (total_tc_mb_late*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_distancebudget;" + (total_tc_mb_distancebudget*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_desttype_target;" + (total_tc_mb_desttype_target*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_desttype_nature;" + (total_tc_mb_desttype_nature*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
		save (";total_tc_mb_desttype_hwn;" + (total_tc_mb_desttype_hwn*modeling_reduction_factor)) to:file_output + filename rewrite:false type:"text";
	}


	// ------------------------------------------------------------------------
	// (1)ACTION@global to get the index of a random element of a weighted list 
	// ------------------------------------------------------------------------
	action get_random_value_of_weighted_list (list<int> the_arguments) {
		//initilize variables
		list<int> the_list; int index_val;
		// build the list with the limits
		loop i from: 0 to: (length(the_arguments)-1) { add (the_arguments[i] + sum(copy_between(the_arguments,0,i))) to: the_list; }
		// generate a random number within 1 ... the_lists maximum
		int random_val <- rnd (max(the_list)-1) + 1;	
		// find the matching index-value of the original list
		loop index_val from: 0 to: (length(the_list)-1) { 	if (random_val <= the_list[index_val]) {break;} }
		// return the value (element)
		return index_val;
	}
	// ------------------------------------------------------------------------

}


// =========================================================================================================
// S P E C I E S - Section
// =========================================================================================================

// ---------------------------------------------------------------------------------------
// SPECIES: ways
// ---------------------------------------------------------------------------------------
species ways {
	// attributes from the shapefile
	int shape_objectid;							// OBJECTID (from ArcGIS)
	string shape_wayid;							// way number
	string shape_name;							// wayname
	int shape_wayid_planning;				// planning for 2020 for this way (1 = closing this way)
	int shape_summer_hiking;				// summer hiking
	int shape_winter_hiking;				// winter hiking
	int shape_thesis_nomaxcount;		// this way should not count for the possible maximum use by tc (e.g. at the Brocken summit)
	int shape_way_category;					// category of this way (small, broad, street, etc.) 		
	int shape_way_nature;						// way is nature oriented 		
	int shape_way_difficulty;				// difficulty level of this way (hard to go there?) 

	// variables and attributes
	float way_difficulty_factor_summer <- 0.0;		// calculated weight of this way for the summer
	float way_difficulty_factor_winter <- 0.0;		// calculated weight of this way for the winter

	// map values
	int colorValue;																// value representing the hiker-density on this way 
	rgb drawcolor;																// RGB-color-value representing the hiker-density on this way

	// statistical values (for density)
	float tc_on_way <- 0.0 update: 0.0;						// how much (partial) tc were on this ways at this cycle?
	float sum_tc_on_way <- 0.0;										// sum of all (partial) tc on this ways (summed up all cycles)
	float avg_tc_on_way <- 0.0;										// average of the sum of all (partial) tc on this way over all cycles     
	float max_tc_on_way <- 0.0;										// maximum of the sum of all (partial) tc on this way over all cycles

	// statistical values (for total values)
	int tc_used_way <- 0 update: 0;								// how much tc were on this way this cycle
	int sum_tc_used_way <- 0;											// sum of the number of all tc seen at all cycles on this way
	
	// statistical values (for counting tc)
	list<string> list_tc_hiked_way <- [];					// list of tc and timestamp who hiked this way
	int count_tc_hiked_way <-0;										// number of tc who hiked this way
	int count_tc_members_hiked_way <-0;						// number of hikers who hiked this way
	int count_tc_nature_hiked_way <- 0;						// number of close to nature tc who hiked this way
	int count_tc_members_nature_hiked_way <-0;		// number of close to nature hikers who hiked this way
	int count_tc_BROCKEN_hiked_way <- 0;					// number of Brocken tc who hiked this way 
	int count_tc_members_BROCKEN_hiked_way <- 0;	// number of Brocken hikers who hiked this way

	// statistical values (for the usage)
	float usage_percent <- 0.0;										// the usage (in percent) of this way of all members of ALL touring companys
	int usage_percent_category <- 0;							// categorized usage of this way (see above)

	// base aspect
	aspect draw_ways {

		// calculate the color regarding the ways' usage
		// exclude the NMA-marked ways e.g. at the Brocken plateau, because they are extraordinary heavily used  		
		colorValue <- int(255 * count_tc_members_hiked_way / max([1,max(ways where(each.shape_thesis_nomaxcount != 1) collect(each.count_tc_members_hiked_way))]));
		if colorValue > 255 {colorValue <- 255;}
		drawcolor <- rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0);

		if (	set_season_type = "summer2011"
					and shape_summer_hiking != 0
		) {
				if (count_tc_members_hiked_way = 0) {
						draw (shape + ways_symbol_size_unsed*(3/#zoom + 0.8)) color:ways_color;
					} else {
						draw (shape + ways_symbol_size_used*(3/#zoom + 0.8)) color:drawcolor;
				}
	
			} else if (	set_season_type = "winter2011"
									and shape_winter_hiking != 0
			) {
				if (count_tc_members_hiked_way = 0) {
						draw (shape + ways_symbol_size_unsed*(3/#zoom + 0.8)) color:ways_color;
					} else {
						draw (shape + ways_symbol_size_used*(3/#zoom + 0.8)) color:drawcolor;
				}

			} else if (	set_season_type = "summer2020"
									and shape_summer_hiking != 0
									and shape_wayid_planning != 1
			) {
				if (count_tc_members_hiked_way = 0) {
						draw (shape + ways_symbol_size_unsed*(3/#zoom + 0.8)) color:ways_color;
					} else {
						draw (shape + ways_symbol_size_used*(3/#zoom + 0.8)) color:drawcolor;
				}

			} else if (	set_season_type = "winter2020"
									and shape_winter_hiking != 0
									and shape_wayid_planning != 1
			) {
				if (count_tc_members_hiked_way = 0) {
						draw (shape + ways_symbol_size_unsed*(3/#zoom + 0.8)) color:ways_color;
					} else {
						draw (shape + ways_symbol_size_used*(3/#zoom + 0.8)) color:drawcolor;
				}

		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: parking(-areas)
// ---------------------------------------------------------------------------------------
species parking {
	// attributes from the shapefile
	int shape_objectid;							// OBJECTID (from ArcGIS) 
	int shape_id;										// ID (primarykey)
	string shape_name;							// name of parking-area
	string shape_city;							// type of parking-area
	int shape_attraction;						// attraction of parking-area (how well-known is this parking-area?) 
	int shape_attraction_stopover;	// attraction of parking-area (how well-known is this parking-area?) for stopovers
	int shape_attraction_train;			// attraction of parking-area for hiking back from a train station
	int shape_capacity;							// whats the capacity of this parking area?

	// variables and attributes
	int sum_tc_home <- 0;									// total number of tc which started from here
	int sum_tc_members_home <- 0;					// total number of hikers which started from here
	int sum_tc_BROCKEN <- 0;							// total number of Brocken tc which started from here
	int sum_tc_members_BROCKEN <- 0;			// total number of Brocken hikers which started from here
	int sum_tc_home_last <- 0;						// total number of tc which started from here during the last simulation cycle
	int sum_tc_members_home_last <- 0;		// total number of hikers which started from here during the last simulation cycle
	int sum_tc_BROCKEN_last <- 0;					// total number of Brocken tc which started from here during the last simulation cycle
	int sum_tc_members_BROCKEN_last <- 0;	// total number of Brocken hikers which started from here during the last simulation cycle
	int tc_home_now <- 0;									// number of tc which started from here actually and are still on their way 
	int tc_mb_home_now <- 0;							// number of hikers which started from here actually and are still on their way

	list<float> list_tc_home_now <- [];			// list of all tc which are currently on their way and started from here
	list<float> list_tc_mb_home_now <- [];	// list of all hikers which are currently on their way and started from here

	// base aspect
	aspect draw_parking {
		draw geometry:square(parking_symbol_size*(3/#zoom + 0.8)) color:parking_color;
		if show_parking_id {
			draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color: parking_color;
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: bus (-stops)
// ---------------------------------------------------------------------------------------
species bus {
	// attributes from the shapefile
	int shape_objectid;					// OBJECTID (from ArcGIS) 
	int shape_id;								// ID (primarykey)
	string shape_name;					// name of parking-area
	int shape_attraction;				// attraction of parking-area (how well-known is this parking-area?) 
	int shape_attraction_train;	// attraction of parking-area for hiking back from a train station

	// variables and attributes
	int sum_tc_home <- 0;							// total number of tc which started from here
	int sum_tc_members_home <- 0;			// total number of hikers which started from here
	int sum_tc_BROCKEN <- 0;					// total number of Brocken tc which started from here
	int sum_tc_members_BROCKEN <- 0;	// total number of Brocken hikers which started from here
	int tc_home_now <- 0;							// number of tc which started from here actually and are still on their way 
	
	// base aspect
	aspect draw_bus {
		draw geometry:square(bus_symbol_size*(3/#zoom + 0.8)) color:bus_color;
		if show_bus_id {
			draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:bus_color;
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: towns
// ---------------------------------------------------------------------------------------
species towns {
	// attributes from the shapefile
	int shape_objectid;					// OBJECTID (from ArcGIS) 
	int shape_id;								// ID (primarykey)
	string shape_name;					// name of parking-area
	int shape_attraction;				// attraction of parking-area (how well-known is this parking-area?) 
	int shape_attraction_train;	// attraction of parking-area for hiking back from a train station

	// variables and attributes
	int sum_tc_home <- 0;							// total number of tc which started from here
	int sum_tc_members_home <- 0;			// total number of hikers which started from here
	int sum_tc_BROCKEN <- 0;					// total number of Brocken tc which started from here
	int sum_tc_members_BROCKEN <- 0;	// total number of Brocken hikers which started from here
	int tc_home_now <- 0;							// number of tc which started from here actually and are still on their way
	
	// base aspect
	aspect draw_towns {
		draw geometry:square(town_symbol_size*(3/#zoom + 0.8)) color:town_color;
		if show_town_id {
			draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:town_color;
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: train (-stations)
// ---------------------------------------------------------------------------------------
species train {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 
	int shape_id;					// ID (primarykey)
	string shape_name;		// name of parking-area
	int shape_attraction;	// attraction of train station (how well-known is this train station?) 

	// variables and attributes
	int sum_tc_home <- 0;					// total number of tc which started from here
	int sum_tc_members_home <- 0;	// total number of hikers which started from here
	int tc_home_now <- 0;					// number of tc which started from here actually and are still on their way 
	
	// base aspect
	aspect draw_train {
		draw geometry:square(train_symbol_size*(3/#zoom + 0.8)) color:train_train_color;
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: pois
// ---------------------------------------------------------------------------------------
species pois {
	// attributes from the shapefile
	int shape_objectid;						// OBJECTID (from ArcGIS) 
	int shape_id;									// ID (primarykey)
	string shape_name;						// name of POI
	string shape_type;						// type of POI
	int shape_attraction;					// attraction of POI (how important is this POI?) 
	int shape_nearbyparking;			// is there a nearby P?	
	int shape_primary;						// is this a primary POI where people want to hike to?
	int shape_summer;							// reachable during the summer
	int shape_winter;							// reachable during the winter
	int shape_attraction_add;			// attraction of POI as an additional POI / target
	int shape_attraction_nature;	// 	attraction of POI for close to nature hikers
	int shape_add_probability;		// special probability to add this POI as an additional one 

	// variables and attributes
	int tc_at_target <- 0;									// total number of tc who have visited this POI
	int tc_members_at_target <- 0;					// total number of hikers who have visited this POI
	int tc_nature_at_target <- 0;						// total number of close to nature tc who have visited this POI
	int tc_members_nature_at_target <- 0;		// total number of close to nature hikers who have visited this POI
	int tc_BROCKEN_at_target <- 0;					// total number of Brocken tc who have visited this POI
	int tc_members_BROCKEN_at_target <- 0;	// total number of Brocken hikers who have visited this POI
	
	// base aspect
	aspect draw_pois {

		if (	(	set_season_type = "summer2011" or set_season_type = "summer2020")
					and shape_summer = 1
				) {
				// all types of summer
				if (shape_primary = 1) {
					// primary POI (target)
					draw geometry:triangle(pois_symbol_size*(3/#zoom + 0.8)) color:pois_color_primary;
					if show_poi_id {
						draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:pois_color_primary;
					}
				} else {
					// secondary POI (target)
					draw geometry:triangle(pois_symbol_size/2*(3/#zoom + 0.8)) color:pois_color_secondary;
					if show_poi_id {
						draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:pois_color_secondary;
					}					
				}

			} else if (	(	set_season_type = "winter2011" or set_season_type = "winter2020")
									and shape_winter = 1
								) {
				// all types of winter
				if (shape_primary = 1) {
					// primary POI (target)
					draw geometry:triangle(pois_symbol_size*(3/#zoom + 0.8)) color:pois_color_primary;
					if show_poi_id {
						draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:pois_color_primary;
					}
				} else {
					// secondary POI (target)
					draw geometry:triangle(pois_symbol_size/2*(3/#zoom + 0.8)) color:pois_color_secondary;
					if show_poi_id {
						draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#bold) color:pois_color_secondary;
					}					
				}
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: ca (countingarea)
// ---------------------------------------------------------------------------------------
species ca {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 
	int shape_id;					// ID (primarykey)
	string shape_name;		// name
	string shape_type;		// type

	// map values
	int colorValue;																// value representing the hiker-density in this counting area 
	rgb drawcolor;																// RGB-color-value representing the hiker-density in this counting area

	// variables and attributes
	int tc_in_area <- 0;													// number of tc this simulation cycle in this counting area
	int tc_members_in_area <- 0;									// number of hikers this simulation cycle in this counting area
	int sum_tc_in_area <- 0;											// total number of tc in this counting area
	int sum_tc_members_in_area <- 0;							// total number of hikers in this counting area

	list<string> list_tc_hiked_area <- [];				// list of all tc and their timestamp without subsequent counting
	int count_tc_hiked_area <- 0;									// total number of tc in this couting area without subsequent counting
	int count_tc_members_hiked_area <- 0;					// total number of hikers in this couting area without subsequent counting

	list<string> list_tc_hiked_area_once <- [];		// list of all tc and their timestamp
	int count_tc_hiked_area_once <- 0;						// absolut total number of tc in this couting area
	int count_tc_members_hiked_area_once <- 0;		// absolut total number of hikers in this couting area

	float percentage_mb_area <- 0.0 update:(countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0);

	// draw types with 'Revier' (territory), lighter colors
	aspect draw_ca_Revier {
		if (not(display_heatmap) and shape_type = 'Revier' and (display_areas = 'ALL' or display_areas = 'Revier')) {
				colorValue <- int(128 * count_tc_members_hiked_area_once / max([1,max(list_count_tc_members_hiked_area_1_once)]));
				drawcolor <- rgb(128+colorValue,255-colorValue,128);
				if ((countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
					draw (shape) color:drawcolor;
					if (show_percentage_area and (countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
						draw string(countcomplete[0].count_tc_members_hiked_countcomplete>0 ? int(count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100*10)/10 : 0) at:point(self.location.x-150,self.location.y+100) font:font('Arial',10,#flat) color:#dimgray;
					}
				}
				if show_counting_id {
					draw string(shape_id) at:point(self.location.x,self.location.y) font:font('Arial',12,#bold) color:#black;
				}
		}
	}

	// draw types with 'Bereich' (area), darker colors
	aspect draw_ca_Bereich {
 			if (not(display_heatmap)and shape_type = 'Bereich' and (display_areas = 'ALL' or display_areas = 'Bereich')) {
 			colorValue <- int(255 * count_tc_members_hiked_area_once / max([1,max(list_count_tc_members_hiked_area_2_once)]));
				drawcolor <- rgb(colorValue,255-colorValue,0);
				if ((countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
					draw (shape) color:drawcolor;
					if (show_percentage_area and (countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
						draw string(countcomplete[0].count_tc_members_hiked_countcomplete>0 ? int(count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*100*10)/10 : 0) at:point(self.location.x-150,self.location.y+100) font:font('Arial',10,#flat) color:#dimgray;
					}
				}
				if show_counting_id {
					draw string(shape_id) at:point(self.location.x,self.location.y) font:font('Arial',12,#bold) color:#black;
				}
			}
	}

}


// ---------------------------------------------------------------------------------------
// SPECIES: cp (countingpoint)
// ---------------------------------------------------------------------------------------
species cp {
	// attributes from the shapefile
	int shape_objectid;				// OBJECTID (from ArcGIS) 
	int shape_id;							// ID (primarykey)
	string shape_name;				// name
	int shape_cp;							// cp ID
	int shape_subpoint;				// subpoint of a cp (1|2)
	int shape_direction;			// direction to which subpoint this subpoint will point to 

	// variables and attributes
	int tc_at_cp <- 0 update:0;									// number of counted tc in both directions during the actual cycle
	int tc_heading_dir1 <- 0 update:0;					// number of counted tc in direction 1 during the actual cycle
	int tc_heading_dir2 <- 0 update:0;					// number of counted tc in direction 2 during the actual cycle
	int tc_members_at_cp <- 0 update:0;					// number of counted hikers in both directions during the actual cycle
	int tc_members_heading_dir1 <- 0 update:0;	// number of counted hikers in direction 1 during the actual cycle
	int tc_members_heading_dir2 <- 0 update:0;	// number of counted hikers in direction 1 during the actual cycle

	int sum_tc_at_cp <- 0;											// total number of tc in both directions
	int sum_tc_heading_dir1 <- 0;								// total number of tc in direction 1
	int sum_tc_heading_dir2 <- 0;								// total number of tc in direction 2
	int sum_tc_members_at_cp <- 0;							// total number of hikers in both directions
	int sum_tc_members_heading_dir1 <- 0;				// total number of hikers in direction 1
	int sum_tc_members_heading_dir2 <- 0;				// total number of hikers in direction 2

	// base aspect
	aspect draw_cp {
		draw geometry:square(cp_symbol_size*(3/#zoom + 0.8)) color:cp_color;
		if show_counting_id {
			draw string(shape_id) at:point(self.location.x+120,self.location.y+90) font:font('Arial',12,#plain) color:cp_color;
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: railway (only to display it)
// ---------------------------------------------------------------------------------------
species railway {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 

	// base aspect
	aspect draw_railway {
		draw (shape + railway_symbol_size*(3/#zoom + 0.5)) color:railway_color;
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: street (only display it)
// ---------------------------------------------------------------------------------------
species street {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 

	// base aspect
	aspect draw_street {
		draw (shape + street_symbol_size*(3/#zoom + 0.5)) color:street_color;
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: nlp (displaying additional info from the simulation and as a countingarea)
// ---------------------------------------------------------------------------------------
species nlp {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 

	// base aspect
	aspect draw_nlp {
		draw (shape + nlp_symbol_size*(3/#zoom + 0.5)) color:nlp_color;
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: heatmap
// ---------------------------------------------------------------------------------------
species heatmap {
	// attributes from the shapefile
	int shape_id;		// ID 

	// map values
	int colorValue;																// value representing the hiker-density 
	rgb drawcolor;																// RGB-color-value representing the hiker-density

	// variables and attributes
	int tc_in_heatmap <- 0;												// number of tc this simulation cycle
	int sum_tc_in_heatmap <- 0;										// total number of tc
	int tc_members_in_heatmap <- 0;								// number of hikers this simulation cycle
	int sum_tc_members_in_heatmap <- 0;						// total number of hikers

	list<string> list_tc_hiked_heatmap <- [];			// list of all tc and their timestamp without subsequent counting
	int count_tc_hiked_heatmap <- 0;							// total number of tc without subsequent counting
	int count_tc_members_hiked_heatmap <- 0;			// total number of hikers without subsequent counting
	float percentage_mb_heatmap <- 0.0 update:(countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_heatmap/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0);
																								// percentage of all hikers this simulation cycle
		
	// draw with lighter colors
	aspect draw_heatmap {
		if (display_heatmap) {
				colorValue <- int(128 * count_tc_members_hiked_heatmap / max([1,max(list_count_tc_members_hiked_heatmap)]));
				if ((countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_heatmap/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
						drawcolor <- rgb(128+colorValue,255-colorValue,128);
					} else {
						drawcolor <- rgb(255,255,255);
				}
				draw (shape) color:drawcolor;
				if (show_percentage_area and (countcomplete[0].count_tc_members_hiked_countcomplete>0 ? count_tc_members_hiked_heatmap/countcomplete[0].count_tc_members_hiked_countcomplete*100 : 0) >= colorizing_min_perc){
					draw string(countcomplete[0].count_tc_members_hiked_countcomplete>0 ? int(count_tc_members_hiked_heatmap/countcomplete[0].count_tc_members_hiked_countcomplete*100*10)/10 : 0) at:point(self.location.x-150,self.location.y+100) font:font('Arial',10,#flat) color:#dimgray;
				}
		}
	}
}


// ---------------------------------------------------------------------------------------
// SPECIES: countcomplete
// ---------------------------------------------------------------------------------------
species countcomplete {
	// attributes from the shapefile
	int shape_objectid;		// OBJECTID (from ArcGIS) 

	// variables and attributes
	int tc_in_countcomplete <- 0;											// number of tc this simulation cycle
	int sum_tc_in_countcomplete <- 0;									// total number of tc
	int tc_members_in_countcomplete <- 0;							// number of hikers this simulation cycle
	int sum_tc_members_in_countcomplete <- 0;					// total number of hikers

	list<string> list_tc_hiked_countcomplete <- [];		// list of all tc and their timestamp without subsequent counting
	int count_tc_hiked_countcomplete <- 0;						// total number of tc without subsequent counting
	int count_tc_members_hiked_countcomplete <- 0;		// total number of hikers without subsequent counting

}


// ---------------------------------------------------------------------------------------
// SPECIES: tc (touringcompany)
// ---------------------------------------------------------------------------------------
species tc skills:[moving] {
	int tc_id; 																							// id of this tc
	int tc_members;																					// number of hikers
	float tc_max_hiking_distance;														// maximum distance this tc would like to hike
	string tc_starttype;																		// flag for the starttype (parking, bus, town, train)
	string tc_startsubtype <-nil;														// flag for the startsubtype (go back by train or hike down to the valley)
	string tc_destinationtype;															// type of tc (target, nature, hwn)
	string tc_status;																				// actual status of this tc (various states, see documentation)
	int tc_startcycle;																			// cyle of the actual day this tc will start (ranging from 1-144)
	bool tc_waits <- false update:false;										// statevariable to indicate whether this tc has to wait at least one cycle at its target
	int tc_restingattarget_cycles;													// number of cycles this tc will rest at its target
	int tc_restingattarget_cycles_left;											// number of resting cycles left
	path path_followed;																			// list of segments (edges) of the actual way this tc has choosen
	bool was_inside_nlp <- false;														// flag to mark a tc which was inside the national park area
	bool was_inside_BROCKEN <- false;												// flag to mark tc which where at the Brocken
	float tc_hiked_distance <- 0.0;													// total hiked distance of this tc
	float local_tc_max_hiking_distance <- 0.0 update:0.0;		// maximum hiking distance at a local aspect
	bool alarm_touringcompany_path <- false;								// alarmtriggering for several unknown states, useful during programming the model
	list<int> list_ways_tc_hiked <- [];											// list of all ways this tc has hiked
	list<point> list_tc_target_points <- [];								// list of the coordinates of the POI to go
	list<point> list_tc_total_target_points <- [];					// list of the coordinates this tc has gone so far
	list<point> list_tc_notarget_points <- [];							// list of the coordinates of the unwanted POI 
	
	// ---------------------------------------------------------------------------------------
	// tc: moving the hikinggroup
	// ---------------------------------------------------------------------------------------
	reflex move_tc {

		// (1) set first target and set the starting point ("home")
		if (tc_status = 'setup') {

			// start this tc at the right moment
			if (tc_startcycle <= mod(cycle,date_cycles_per_simulation_day)) {

				// increase the number of tc that have started from this location 
				if (tc_starttype = 'parking') {
						ask parking(first(list_tc_target_points)) {
							tc_home_now <- tc_home_now + 1;
							tc_mb_home_now <- tc_mb_home_now + myself.tc_members; 
						} 
					} else if (tc_starttype = 'bus') {
						ask bus(first(list_tc_target_points)) {
							tc_home_now <- tc_home_now + 1;
						} 
					} else if (tc_starttype = 'train') {
						ask train(first(list_tc_target_points)) {
							tc_home_now <- tc_home_now + 1;
						} 
					} else if (tc_starttype = 'town') {
						ask towns(first(list_tc_target_points)) {
							tc_home_now <- tc_home_now + 1;
						} 
				}

				// differentiate between train_train, train_valley and all others
				// a) set the location (to make this tc "visible")
				// b) set the tc_destinationtype or leave untouched
				// c) set the local hiking distance for finding the right POIs
				if (tc_startsubtype = 'bytrain_valley') {
						// start at the train station at the Brocken (ID=0)!
						location <- point(train[0]);
						// reduce the distance for the first POI to the one needed for the Brocken 
						local_tc_max_hiking_distance <- tc_standard_hiking_distance_localized / 2;

					} else if (tc_startsubtype = 'bytrain_train') {
						// start at the train station at the Brocken (ID=0)!
						location <- point(train[0]);
						// reduce the distance for the first POI to the one needed for the Brocken 
						local_tc_max_hiking_distance <- tc_standard_hiking_distance_localized / 2;
						// all hikers gone by train are of the type 'target'
						tc_destinationtype <- 'target';

					} else {
						// start at the first "target" point, which is the starting location!
						location <- first(list_tc_target_points);
						// reduce the distance for the first POI to the one needed for the Brocken 
						local_tc_max_hiking_distance <- tc_max_hiking_distance / 2;
				}

				// find a POI as a target
				do find_and_set_target;

				// Output of the actual machine_time core messages
				if (write_core_message = true) {write "~~~ ta=" + machine_time + "(delta=" + (machine_time - t1) + ") --> end initial setup of " + self; t1 <- machine_time;}

			}
		}

		// (2) set new target for touringcompany to get back home,
		// after it rested for at least 1 cycle at the target (thats why this is BEFORE (3)!)
		// but the tc has to stay at the target for some time (resting at target cycles)
		if (tc_status = 'target') {
			if (tc_restingattarget_cycles_left > 0) {
					// there is still time to rest at the target, reduce the pausing time by one cycle
					tc_restingattarget_cycles_left <- tc_restingattarget_cycles_left - 1;
				} else {
					// pause is over, let's go hiking again to the NEXT target
					if (length(list_tc_target_points) > 1) {
							tc_status <- 'hikingtarget';
						} else {
							tc_status <- 'hikinghome';
							// now, while hiking home, we are ready to try the additional targets again
							// if we don't use them while hiking to the target
							list_tc_notarget_points <- [];
						}
			}
		}

		// (3) touringcompany reached the POI target
		// remove this target from it's list
		if (tc_status = 'hikingtarget' and last(list_tc_target_points) = location) {
			// set the status
			tc_status <- 'target';

			// if this is a restaurant (Waldgaststaette) increase the resting time
			if (pois(last(list_tc_target_points)).shape_type = 'Waldgaststaette') {
				tc_restingattarget_cycles <- tc_restingattarget_cycles + 3;
			}

			// how long will this tc rest at the target (1 cycle will be the model's minmimum)		
			if (tc_restingattarget_cycles > 0) {
					tc_restingattarget_cycles_left <- tc_restingattarget_cycles - 1;
				} else {
					tc_restingattarget_cycles_left <- 0;
			}

			// count this touringcompany and its members at this target
			ask pois(last(list_tc_target_points)) {
				tc_at_target <- tc_at_target + 1; 
				tc_members_at_target <- tc_members_at_target + myself.tc_members;
				
				// is this a closed to nature touring company?
				if (myself.tc_destinationtype = 'nature') {
					tc_nature_at_target <- tc_nature_at_target + 1;
					tc_members_nature_at_target <- tc_members_nature_at_target + myself.tc_members;
				}

				// this tc was at the Brocken
				if (myself.was_inside_BROCKEN = true) {
					tc_BROCKEN_at_target <- tc_BROCKEN_at_target + 1;
					tc_members_BROCKEN_at_target <- tc_members_BROCKEN_at_target + myself.tc_members;
				}
			}

			// and now remove this target from the target-list for this tc
			remove last(list_tc_target_points) from: list_tc_target_points;
		}

		// (4) touringcompany leaves the investigtationarea
		// after it rested for 1 cycle at the home (that's why this is BEFORE (5)!),
		// free some space at  the corresponding parking area
		if (tc_status = 'home') {
			if (tc_starttype = 'parking') {
					ask parking(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
						tc_mb_home_now <- tc_mb_home_now - myself.tc_members; 
					}
				} else if (tc_starttype = 'bus') {
					ask bus(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
					}
				} else if (tc_starttype = 'town') {
					ask towns(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
					}
				} else if (tc_starttype = 'train') {
					ask train(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
					}
			}
			
			// check the hiking distance whether this is okay or not
			if (tc_hiked_distance > tc_max_hiking_distance) {
				total_tc_distancebudget <- total_tc_distancebudget + 1;
				total_tc_mb_distancebudget <- total_tc_mb_distancebudget + tc_members;
			}

			// say "Good Bye"
			do die;
		}
	
		// (5) touringcompany reached its home (target) as it's final position
		// leave this last target at the target list because we need to free the space
		if (tc_status = 'hikinghome' and location = first(list_tc_target_points)) {
			tc_status <- 'home';
		}

		// (6) touringcompany has no possible target, leave the investigation area (after one cycle of waiting)
		// and free some space at the corresponding home location
		if (tc_status = 'notarget' and not tc_waits) {
			if (tc_starttype = 'parking') {
					ask parking(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
						tc_mb_home_now <- tc_mb_home_now - myself.tc_members; 
					}
				} else if (tc_starttype = 'bus') {
					ask bus(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
				}
				} else if (tc_starttype = 'town') {
					ask towns(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
					}
				} else if (tc_starttype = 'train') {
					ask train(first(list_tc_target_points)) {
						tc_home_now <- tc_home_now - 1;
					}
			}
			do die;
		}

		// (7) touringcompany has no space at any parkingarea, leave the investigation area
		// and there is no need to free some space at any parking area!
		if (tc_status = 'nospace') {

			// say "Good Bye"
			do die;
		}

		// Now really MOVE the tc to the target (after checking all the different states and
		// its changes and also the possible additional POIs)
		do move_one_tc; 
	}


	// ---------------------------------------------------------------------------------------
	// tc: find an set a (main) target for tc 
	// ---------------------------------------------------------------------------------------
	action find_and_set_target {
		// get all possible primary POIs which are within an acceptable hiking distance
		// and which are NOT within the critical distance to another parking area
		// and which are suitable for the 'destinationtype' of the tc
		// but not on the POI target list, already (because train adds always the Brocken as a POI)
		list<pois> possibletargetpois <- [];
		if (tc_destinationtype = 'target' or tc_destinationtype = 'hwn') {
			// "target" and "hwn" touring companys use primary targets
				loop po over:pois_primary {
					// use the normal ways_graph (tc_destinationtype='target' or 'hwn')
					float path_distance <- self distance_to po using topology(ways_graph);
					if (
						// TARGET --> takes all POIs
									(	(tc_destinationtype = 'target')
										and (path_distance <= local_tc_max_hiking_distance)
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and (po.shape_nearbyparking = 0)
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)
								or
									(	(tc_destinationtype = 'target')
										and (path_distance <= local_tc_max_hiking_distance)
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and (po.shape_nearbyparking = 1 and path_distance <= nearbyparking_path_distance)
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)

						// HWN --> _only_ takes POIs which are "Stempelstelle"
								or
									(	(tc_destinationtype = 'hwn')
										and (path_distance <= local_tc_max_hiking_distance)
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and po.shape_type = 'Stempelstelle'
										and (po.shape_nearbyparking = 0)
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)
								or
									(	(tc_destinationtype = 'hwn')
										and path_distance <= local_tc_max_hiking_distance
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and po.shape_type = 'Stempelstelle'
										and (po.shape_nearbyparking = 1 and path_distance <= nearbyparking_path_distance)
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)

							) {
						add (po) to: possibletargetpois;
					}
				}
			} else if (tc_destinationtype = 'nature') {
				loop po over:pois_all {
					// use the special ways_graph_nature (tc_destinationtype='nature')
					float path_distance <- self distance_to po using topology(ways_graph_nature);
					if (
						// NATURE --> takes all POIs and also the secondary POIs (which are the huts and picknick-places)
						// and looks for "Aussichtspunkte" and "Rastplätze", because they are more "nature like"
									(	(tc_destinationtype = 'nature')
										and path_distance <= local_tc_max_hiking_distance
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and po.shape_nearbyparking = 0
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)
								or
									(	(tc_destinationtype = 'nature')
										and path_distance <= local_tc_max_hiking_distance
										and ( ( (2*path_distance/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ((tc_lastlightcycle * step) - ((mod(cycle,date_cycles_per_simulation_day))* step)) )
										and (po.shape_nearbyparking = 1 and path_distance <= nearbyparking_path_distance)
										and (po.shape_attraction != 0)
										and not(list_tc_total_target_points contains point(po))
								)

							) {
						add (po) to: possibletargetpois;
					}
				}
		}			

		// set the randomized POI from the possible POIs
		list<int> pois_weighted_list <- [];
		if (tc_destinationtype = 'nature') {
				pois_weighted_list <- possibletargetpois collect each.shape_attraction_nature;
			} else {
				pois_weighted_list <- possibletargetpois collect each.shape_attraction;
		}

		if (length(pois_weighted_list) != 0) {
				// found a POI within the hiking distance
				tc_status <- 'hikingtarget';
				int random_weighted_poi <- int(get_random_value_of_weighted_list (pois_weighted_list));
				point tc_target <- point(possibletargetpois[random_weighted_poi]);  
				add tc_target to:list_tc_target_points;
				add tc_target to:list_tc_total_target_points;
			} else {
				// found no POI within the hiking distance 
				// TRY to set off this tc somewhere within it's hiking distance to take a little walk
				// otherwise there is really no target! Don't worry about the daylight-time because its only a short walk 
				// use the normal ways_graph
				list possiblelocation <- one_of(ways_graph.vertices at_distance (0.75*local_tc_max_hiking_distance) using topology(ways_graph));
				if (length(possiblelocation) > 0) {
						tc_status <- 'hikingtarget';
						point tc_target <- any_location_in(point(possiblelocation));
						add tc_target to:list_tc_target_points;
						add tc_target to:list_tc_total_target_points;
					} else {
						tc_status <- 'notarget';
						tc_waits <- true;
						total_tc_notarget <- total_tc_notarget + 1;
						total_tc_mb_notarget <- total_tc_mb_notarget + tc_members;
				}
		}
	}


	// ---------------------------------------------------------------------------------------
	// tc: move one tc along the calculated route
	// ---------------------------------------------------------------------------------------
	action move_one_tc {
		if (tc_status = 'hikingtarget' or tc_status = 'hikinghome') {
			// we should look for additional targets if
			// a) additional targets are included in the model
			// b) less than the max addiotnal targets have been added (list_tc_total_target_points)
			// c) there is actually no additional target for this tc
			if (	goto_additional_targets = true				
						and (	
									(	// normal conditions "out in the field"
										length(list_tc_total_target_points) < (2 + tc_max_additional_targets)
										and length(list_tc_target_points) <= tc_max_targets_atonce
									)
									or
									(	// special condition(1): TC is near it's home location and might visit e.g. a restaurant 
										tc_status = 'hikinghome'
										and (self distance_to first(list_tc_target_points)) < 1000
									)
								)
				) {

				// add_additional_target
				do add_addition_targets;

			} // END generally look for additional targets 

			// moving the tc towards it's next target (the last one in the list)
			// decide which ways_graph we use
			if (tc_destinationtype = 'nature') {
		    	path path_to_follow_nature <- path_between(ways_graph_nature,location,last(list_tc_target_points));
    			path_followed <- follow (path:path_to_follow_nature, move_weights:weights_map_summer, speed:speed, return_path:true);

				} else {
					path_followed <- goto (target:last(list_tc_target_points), on:ways_graph, recompute_path:false, speed:speed, return_path: true);
			}

			// calculate the hiked distance
			if (path_followed.shape != nil ) {
				tc_hiked_distance <- tc_hiked_distance + path_followed.shape.perimeter;
			}
	
			// calculate statistical values for tc on a way and loop over all used linesegments from last movement
			ways last_way;
			loop linesegments over: path_followed.segments {
				
				// calculate values depending on the perimeter-usage
				ask ways(path_followed agent_from_geometry linesegments) { 
					if (myself.path_followed.shape.perimeter != 0) {
							tc_on_way <- tc_on_way + 1 * (linesegments.perimeter / myself.path_followed.shape.perimeter);
							sum_tc_on_way <- sum_tc_on_way + 1 * (linesegments.perimeter / myself.path_followed.shape.perimeter);
					}
				}
	
				// reached a new way
				if (last_way != ways (path_followed agent_from_geometry linesegments)) {
					// work on every way which was used this move
					ask ways(path_followed agent_from_geometry linesegments) {
	
						// simple statistics: _every_ time at _every_ step this tc is seen on this way
						tc_used_way <- tc_used_way + 1;
						sum_tc_used_way <- sum_tc_used_way + 1;
	
						// complex statistics: is this tc seen more than one time on
						// this way dived by a break of at least one cycle?
						if ((list_tc_hiked_way contains (string(int(myself))+"-"+string(cycle-1)))) {
								// previous cycle found
								remove string(int(myself))+"-"+string(cycle-1) from:list_tc_hiked_way;
								add string(int(myself))+"-"+string(cycle) to:list_tc_hiked_way;
							} else {
								// NO previous cycle found
								add string(int(myself))+"-"+string(cycle) to:list_tc_hiked_way;
								count_tc_members_hiked_way <- count_tc_members_hiked_way + myself.tc_members;

								// is this a closed to nature touring company?
								if (myself.tc_destinationtype = 'nature') {
									count_tc_nature_hiked_way <- count_tc_nature_hiked_way + 1;
									count_tc_members_nature_hiked_way <- count_tc_members_nature_hiked_way + myself.tc_members;
								}

								// was this counted tc at the Brocken?
								if (myself.was_inside_BROCKEN = true) {
									count_tc_BROCKEN_hiked_way <- count_tc_BROCKEN_hiked_way + 1;
									count_tc_members_BROCKEN_hiked_way <- count_tc_members_BROCKEN_hiked_way + myself.tc_members;
								}
						}
						count_tc_hiked_way <- length(list_tc_hiked_way);
	
					}
					last_way <- ways (path_followed agent_from_geometry linesegments);
	
					// store all the used ways at the tc (for later use?)
					if (not(list_ways_tc_hiked contains int(ways(path_followed agent_from_geometry linesegments)))) {
							add int(ways(path_followed agent_from_geometry linesegments)) to:list_ways_tc_hiked;
					}
				}
			}

			// count the tc at a cp
			do count_tc_at_cp;
	
			// check the agent for its normal behaviour and write some alarms if is not in normal operation mode
			if (cycle > 2 and last(list_tc_target_points) != []) {
				// is there a shortest path for a set target?
				// decide which graph to use
				if (tc_destinationtype = 'nature') {
						if (path_between (ways_graph_nature,location,last(list_tc_target_points)) = nil and alarm_touringcompany_path = false) {
							write "##### NIL PATH for nature (" + cycle + ") " + name;
							alarm_touringcompany_path <- true;
							total_nilpath <- total_nilpath + 1; 
						}
					} else {
						if (path_between (ways_graph,location,last(list_tc_target_points)) = nil and alarm_touringcompany_path = false) {
							write "##### NIL PATH for normal (" + cycle + ") " + name;
							alarm_touringcompany_path <- true;
							total_nilpath <- total_nilpath + 1; 
						}
				}
			}

		} // END moving
	}


	// ---------------------------------------------------------------------------------------
	// tc: count the tc at a cp
	// ---------------------------------------------------------------------------------------
	action count_tc_at_cp {
		// calculate the tc at a cp
		list<int> list_cp_passed;
		loop linesegments over: path_followed.segments {
			list<cp> cp_passed <- inside(cp,linesegments);
			if (length(cp_passed) = 1) {
				add int(cp_passed[0]) to:list_cp_passed;
			}
		}
		if (length(list_cp_passed) = 2 or length(list_cp_passed) = 4) {
				// first cp found
				if (cp[list_cp_passed[1]].shape_subpoint = 1 and (length(list_cp_passed) = 2 or length(list_cp_passed) = 4)) {
						// movement towards subpoint 1 (A)
						cp[list_cp_passed[1]].tc_at_cp <- cp[list_cp_passed[1]].tc_at_cp + 1; 
						cp[list_cp_passed[1]].sum_tc_at_cp <- cp[list_cp_passed[1]].sum_tc_at_cp + 1;
						cp[list_cp_passed[1]].tc_heading_dir1 <- cp[list_cp_passed[1]].tc_heading_dir1 + 1; 
						cp[list_cp_passed[1]].sum_tc_heading_dir1 <- cp[list_cp_passed[1]].sum_tc_heading_dir1 + 1; 

						cp[list_cp_passed[1]].tc_members_at_cp <- cp[list_cp_passed[1]].tc_members_at_cp + self.tc_members;
						cp[list_cp_passed[1]].sum_tc_members_at_cp <- cp[list_cp_passed[1]].sum_tc_members_at_cp + self.tc_members;
						cp[list_cp_passed[1]].tc_members_heading_dir1 <- cp[list_cp_passed[1]].tc_members_heading_dir1 + self.tc_members;
						cp[list_cp_passed[1]].sum_tc_members_heading_dir1 <- cp[list_cp_passed[1]].sum_tc_members_heading_dir1 + self.tc_members;
					} else {
						// movement towards subpoint 2 (B)
						cp[list_cp_passed[0]].tc_at_cp <- cp[list_cp_passed[0]].tc_at_cp + 1; 
						cp[list_cp_passed[0]].sum_tc_at_cp <- cp[list_cp_passed[0]].sum_tc_at_cp + 1; 
						cp[list_cp_passed[0]].tc_heading_dir2 <- cp[list_cp_passed[0]].tc_heading_dir2 + 1; 
						cp[list_cp_passed[0]].sum_tc_heading_dir2 <- cp[list_cp_passed[0]].sum_tc_heading_dir2 + 1; 

						cp[list_cp_passed[0]].tc_members_at_cp <- cp[list_cp_passed[0]].tc_members_at_cp + self.tc_members;
						cp[list_cp_passed[0]].sum_tc_members_at_cp <- cp[list_cp_passed[0]].sum_tc_members_at_cp + self.tc_members;
						cp[list_cp_passed[0]].tc_members_heading_dir2 <- cp[list_cp_passed[0]].tc_members_heading_dir2 + self.tc_members;
						cp[list_cp_passed[0]].sum_tc_members_heading_dir2 <- cp[list_cp_passed[0]].sum_tc_members_heading_dir2 + self.tc_members;
			  }

				// second cp found (have to check for the existence of the second one first before checking the direction/order)
				if (length(list_cp_passed) = 4) {
					if (cp[list_cp_passed[3]].shape_subpoint = 1) {
							// movement towards subpoint 1 (A)
							cp[list_cp_passed[3]].tc_at_cp <- cp[list_cp_passed[3]].tc_at_cp + 1; 
							cp[list_cp_passed[3]].sum_tc_at_cp <- cp[list_cp_passed[3]].sum_tc_at_cp + 1;
							cp[list_cp_passed[3]].tc_heading_dir1 <- cp[list_cp_passed[3]].tc_heading_dir1 + 1; 
							cp[list_cp_passed[3]].sum_tc_heading_dir1 <- cp[list_cp_passed[3]].sum_tc_heading_dir1 + 1; 
	
							cp[list_cp_passed[3]].tc_members_at_cp <- cp[list_cp_passed[3]].tc_members_at_cp + self.tc_members;
							cp[list_cp_passed[3]].sum_tc_members_at_cp <- cp[list_cp_passed[3]].sum_tc_members_at_cp + self.tc_members;
							cp[list_cp_passed[3]].tc_members_heading_dir1 <- cp[list_cp_passed[3]].tc_members_heading_dir1 + self.tc_members;
							cp[list_cp_passed[3]].sum_tc_members_heading_dir1 <- cp[list_cp_passed[3]].sum_tc_members_heading_dir1 + self.tc_members;
						} else {
							// movement towards subpoint 2 (B)
							cp[list_cp_passed[2]].tc_at_cp <- cp[list_cp_passed[2]].tc_at_cp + 1; 
							cp[list_cp_passed[2]].sum_tc_at_cp <- cp[list_cp_passed[2]].sum_tc_at_cp + 1; 
							cp[list_cp_passed[2]].tc_heading_dir2 <- cp[list_cp_passed[2]].tc_heading_dir2 + 1; 
							cp[list_cp_passed[2]].sum_tc_heading_dir2 <- cp[list_cp_passed[2]].sum_tc_heading_dir2 + 1; 
	
							cp[list_cp_passed[2]].tc_members_at_cp <- cp[list_cp_passed[2]].tc_members_at_cp + self.tc_members;
							cp[list_cp_passed[2]].sum_tc_members_at_cp <- cp[list_cp_passed[2]].sum_tc_members_at_cp + self.tc_members;
							cp[list_cp_passed[2]].tc_members_heading_dir2 <- cp[list_cp_passed[2]].tc_members_heading_dir2 + self.tc_members;
							cp[list_cp_passed[2]].sum_tc_members_heading_dir2 <- cp[list_cp_passed[2]].sum_tc_members_heading_dir2 + self.tc_members;
				  }
				}
  		} else if (length(list_cp_passed) > 4) {
			  	//write "##### MORE THAN 2 CP: " + length(list_cp_passed) + " CP FOUND AT (" + list_cp_passed + ")!";
					total_morethan2cp <- total_morethan2cp + 1;
		}
	}


	// ---------------------------------------------------------------------------------------
	// tc: look out for additional targets and add them to the target list
	// ---------------------------------------------------------------------------------------
	action add_addition_targets {
		// calculate the needed hiking distance to go to the list of targets
		// and of course back home again! Reduce this amount by 10% to have some safety budget!
		float needed_hiking_distance <- 0.0;
		point last_tp <- location;
		loop tp over:reverse(list_tc_target_points) {
			// decide which way_graph we have to
			if (last_tp != nil and tp != nil) { 
					if (tc_destinationtype = 'nature') {
								needed_hiking_distance <- needed_hiking_distance + last_tp distance_to tp using topology(ways_graph_nature);
						} else {
								needed_hiking_distance <- needed_hiking_distance + last_tp distance_to tp using topology(ways_graph);
					}
				} else {
					needed_hiking_distance <- 1.0;
					write "##### NIL LAST_TP: " + last_tp + ", tp=" + tp;						
			}
			last_tp <- tp; 
		}
		float spare_hiking_distance <- 0.8 * (tc_max_hiking_distance - (tc_hiked_distance + needed_hiking_distance));

		// "safe" the standard possibility for this tc to go to additional POIs,
		// because we might change it now but won't change the set standard
		float tc_probability_to_add_additional_targets_local <- tc_probability_to_add_additional_targets;

		// is there another target in a reachable distance, which is worth to go for?
		// get all possible POIs which are within an acceptable hiking distance
		// but first just only look at the nearby POIs (aerial distance) with a shape_attraction_add other than 0
		list<pois> possibletargetpois <- [];
		bool tc_probability_is_unchanged <- true;
		loop po over:pois_all		where(each.shape_attraction_add != 0)
														at_distance max_additional_poi_aerial_distance {
			// decide which way_graph we have to
			float path_distance <- 0.0;
			if (tc_destinationtype = 'nature') {
				path_distance <- self distance_to po using topology(ways_graph_nature);
				} else {
				path_distance <- self distance_to po using topology(ways_graph);
			}

			// you have to calculate the way two times (forth and back) to be really sure
			// and also add some spare hiking distance for safety reasons
			if (	path_distance <= 0.35 * spare_hiking_distance
						and ( ( ((2*path_distance+needed_hiking_distance)/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ( (tc_lastlightcycle * step) - (mod(cycle,date_cycles_per_simulation_day) * step) ) )
						and not(list_tc_total_target_points contains point(po))
						and not(list_tc_notarget_points contains point(po))
					) {
						add (po) to: possibletargetpois;
						
						// change the probability to go to one of those POIs if they have a special probability 
						// take the HIGHEST one of all found ... (to keep it simple)
						if (po.shape_add_probability != -1) {
							if (tc_probability_is_unchanged) {
								tc_probability_to_add_additional_targets_local <- 0.0;
							}
							if ((po.shape_add_probability/100) > tc_probability_to_add_additional_targets_local) {
								tc_probability_to_add_additional_targets_local <- po.shape_add_probability / 100;
							}
							tc_probability_is_unchanged <- false;
						}
			}
		}

		// SPECIAL CONDITION (1)
		// might there be a suitable restaurant at the end of the tour for this tc?
		// overwrite any possible other possibletargetpois
		list<pois> possibletargetpois_restaurant <- [];
		if (	tc_status = 'hikinghome'
					and (self distance_to first(list_tc_target_points)) < 1000
			) {
				bool tc_probability_is_unchanged <- true;
				loop po over:pois_primary where(	each.shape_attraction_add != 0					// of course only POIs with an additional attraction
																					and each.shape_type = 'Waldgaststaette'	// only the restaurants
																					and each.shape_add_probability != 0			// without locked ones  
																				)
																	at_distance 1000 {

					// decide which way_graph we have to use
					float path_distance <- 0.0;
					if (tc_destinationtype = 'nature') {
						path_distance <- self distance_to po using topology(ways_graph_nature);
						} else {
						path_distance <- self distance_to po using topology(ways_graph);
					}

					if (	path_distance <= 0.35 * spare_hiking_distance
								and ( ( ((2*path_distance+needed_hiking_distance)/speed)+((tc_restingattarget_cycles_mean+tc_restingattarget_cycles_halfrange+3)*step) ) < ( (tc_lastlightcycle * step) - (mod(cycle,date_cycles_per_simulation_day) * step) ) )
								and not(list_tc_total_target_points contains point(po))
							) {
								add (po) to: possibletargetpois_restaurant;
					}
				}
				// found at least one suitable restaurant
				if (length(possibletargetpois_restaurant) != 0) {
					// replace the the list of additional POIs with the restaurant
					possibletargetpois <- possibletargetpois_restaurant;
					total_additional_restaurant_added <- total_additional_restaurant_added + 1; 
					// change the possibility for this tc to go there, take the HIGHEST one of all found ... (to keep it simple)
					loop poadd over:possibletargetpois {
						if (poadd.shape_add_probability != -1) {
							if (tc_probability_is_unchanged) {
								tc_probability_to_add_additional_targets_local <- 0.0;
							}
							if ((poadd.shape_add_probability/100) > tc_probability_to_add_additional_targets_local) {
								tc_probability_to_add_additional_targets_local <- poadd.shape_add_probability / 100;
							}
							tc_probability_is_unchanged <- false;
						}
					}
				}
		} // END special condition (1)

		// ******** if there are any other ADDITIONAL conditions how to choose additional POIs (or change the choosen ones) --> ADD THEM HERE! ********

		// how likeliy it is that this tc adds another POI to it's target list?
		if (flip(tc_probability_to_add_additional_targets_local)) {
				// set the randomized POI from the possible POIs
				list<int> pois_weighted_list <- possibletargetpois collect each.shape_attraction_add;
				if (length(pois_weighted_list) != 0) {
						// found at least one POI within the hiking distance
						total_additional_poi_added <- total_additional_poi_added + 1; 
						tc_status <- 'hikingtarget';
						int random_weighted_poi <- int(get_random_value_of_weighted_list (pois_weighted_list));
						// set this POI as an additional target!
						point tc_target <- point(possibletargetpois[random_weighted_poi]);
						add tc_target to:list_tc_target_points;
						add tc_target to:list_tc_total_target_points;
				}
			} else {
				// do not try to use these POIs again, because this tc don't want to go there
				loop ng over:possibletargetpois {
					add point(ng) to: list_tc_notarget_points;
				}
		} // END flip
	}


	// ---------------------------------------------------------------------------------------
	// tc: aspect draw_tc
	// ---------------------------------------------------------------------------------------
	aspect draw_tc {

		if (display_tc) {
			if (	tc_status = 'setup'
						and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
						and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
			) {
					draw circle(tc_symbol_size*(3/#zoom + 0.8)) color:tc_color_setup;
	
				} else if (	tc_status = 'hikingtarget'
										and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
										and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
										and ((was_inside_nlp=true and display_inside_nlp=true) or (was_inside_nlp=false and display_outside_nlp=true))
					) {
					draw circle(tc_symbol_size*(3/#zoom + 0.8)) color:tc_color_hikingtarget;
					if show_tc_id {
						draw string(int(self)) at:point(self.location.x+label_offset,self.location.y-label_offset) font:font('Arial',12,#plain) color:tc_color_hikingtarget;
					}
	
				} else if (	tc_status = 'target'
										and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
										and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
										and ((was_inside_nlp=true and display_inside_nlp=true) or (was_inside_nlp=false and display_outside_nlp=true))
					) {
					draw circle(tc_symbol_size*(3/#zoom + 0.8)) color:tc_color_target;
					if show_tc_id {
						draw string(int(self)) at:point(self.location.x+label_offset,self.location.y-label_offset) font:font('Arial',12,#plain) color:tc_color_target;
					}
	
				} else if (	tc_status = 'hikinghome'
										and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
										and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
										and ((was_inside_nlp=true and display_inside_nlp=true) or (was_inside_nlp=false and display_outside_nlp=true))
					) {
					draw circle(tc_symbol_size*(3/#zoom + 0.8)) color:tc_color_hikinghome;
					if show_tc_id {
						draw string(int(self)) at:point(self.location.x+label_offset,self.location.y-label_offset) font:font('Arial',12,#plain) color:tc_color_hikinghome;
					}
	
				} else if (	tc_status = 'home'
										and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
										and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
										and ((was_inside_nlp=true and display_inside_nlp=true) or (was_inside_nlp=false and display_outside_nlp=true))
					) {
					draw circle(tc_symbol_size*(3/#zoom + 0.8)) color:tc_color_home;
			}

			if (	show_linetotarget and length(list_tc_target_points) > 0
						and (display_tc_destinationtype = 'ALL' or display_tc_destinationtype = tc_destinationtype)
						and (display_tc_starttype = 'ALL' or display_tc_starttype = tc_starttype)
						and ((was_inside_nlp=true and display_inside_nlp=true) or (was_inside_nlp=false and display_outside_nlp=true))
				) {
				if (tc_status = 'hikingtarget') {
						draw polyline([self.location,last(list_tc_target_points)]) color:pois_color_primary;
					} else if (tc_status = 'hikinghome' and tc_starttype = 'parking') {
						draw polyline([self.location,last(list_tc_target_points)]) color:parking_color;
					} else if (tc_status = 'hikinghome' and tc_starttype = 'bus') {
						draw polyline([self.location,last(list_tc_target_points)]) color:bus_color;
					} else if (tc_status = 'hikinghome' and tc_starttype = 'town') {
						draw polyline([self.location,last(list_tc_target_points)]) color:town_color;
					} else if (tc_status = 'hikinghome' and tc_starttype = 'train' and tc_startsubtype = 'bytrain_train') {
						draw polyline([self.location,last(list_tc_target_points)]) color:train_train_color;
					} else if (tc_status = 'hikinghome' and tc_starttype = 'train' and tc_startsubtype = 'bytrain_valley') {
						draw polyline([self.location,last(list_tc_target_points)]) color:train_valley_color;
				}
			}
		}
	}

	// ------------------------------------------------------------------------
	// (2)ACTION@tc to get the index of a random element of a weighted list 
	// ------------------------------------------------------------------------
	action get_random_value_of_weighted_list (list<int> the_arguments) {
		//initilize variables
		list<int> the_list; int index_val;
		// build the list with the limits
		loop i from: 0 to: (length(the_arguments)-1) { add (the_arguments[i] + sum(copy_between(the_arguments,0,i))) to: the_list; }
		// generate a random number within 1 ... the_lists maximum
		int random_val <- rnd (max(the_list)-1) + 1;	
		// find the matching index-value of the original list
		loop index_val from: 0 to: (length(the_list)-1) { 	if (random_val <= the_list[index_val]) {break;} }
		// return the value (element)
		return index_val;
	}
	// ------------------------------------------------------------------------

}


// =========================================================================================================
// E X P E R I M E N T - Section
// =========================================================================================================
experiment GUI type: gui {

	// ---------------------------------------------------------------------------------------
	// user commands
	// ---------------------------------------------------------------------------------------
	user_command "[Summary]" action:print_summary;
	user_command "[Save Species]" action:save_species_summarys;
	user_command "[Save Val CSV]" action:save_summary_of_values_CSV;
	user_command "[Paths]" action:write_all_shortest_paths;
	user_command "Ways" action:summarize_ways;
	user_command "Parking" action:summarize_parking;
	user_command "Bus" action:summarize_bus;
	user_command "Towns" action:summarize_towns;
	user_command "Train" action:summarize_train;
	user_command "POIs" action:summarize_pois;
	user_command "CA" action:summarize_ca;
	user_command "CP" action:summarize_cp;
	user_command "HM" action:summarize_heatmap;


	// ---------------------------------------------------------------------------------------
	// parameters
	// ---------------------------------------------------------------------------------------
	parameter "standard tc quantity parking [pcs]:" var:standard_number_of_tc_parking category:"Touring companys";
	parameter "standard tc quantity parking stopover [pcs]:" var:standard_number_of_tc_parking_stopover category:"Touring companys";
	parameter "standard tc quantity bus [pcs]:" var:standard_number_of_tc_bus category:"Touring companys";
	parameter "standard tc quantity train [pcs]:" var:standard_number_of_tc_train category:"Touring companys";
	parameter "standard tc quantity town [pcs]:" var:standard_number_of_tc_town category:"Touring companys";
	parameter "Modeling reduction factor [1]:" var:modeling_reduction_factor category:"Touring companys";
	parameter "Members weighted list:" var:tc_members_weighted_list category:"Touring companys";
	parameter "standard hiking_distance [m]:" var:tc_standard_hiking_distance category:"Touring companys";
	parameter "halfrange standard_hiking_distance [m]:" var:tc_standard_hiking_distance_halfrange category:"Touring companys";
	parameter "standard hiking distance localized [m]:" var:tc_standard_hiking_distance_localized category:"Touring companys";
	parameter "standard hiking distance stopover [m]:" var:tc_standard_hiking_distance_stopover category:"Touring companys";
	parameter "Speed [m/s]:" var:tc_standard_speed category:"Touring companys";
	parameter "halfrange speed [m/s]:" var:tc_standard_speed_halfrange category:"Touring companys";
	parameter "Max path dist. nearby-poi [m]:" var:nearbyparking_path_distance category:"Touring companys";
	parameter "halfrange of calc numbers factor:" var:calc_number_of_tc_halfrange_factor category:"Touring companys";
	parameter "Mean of resting at target [cycles]:" var:tc_restingattarget_cycles_mean category:"Touring companys";
	parameter "halfrange of resting at target  [cycles]:" var:tc_restingattarget_cycles_halfrange category:"Touring companys";
	parameter "Goto additional targets:" var:goto_additional_targets category:"Touring companys";
	parameter "Max number of secondary targets [1]" var:tc_max_additional_targets category:"Touring companys";  
	parameter "Number of targets a tc knows [1]" var:tc_max_targets_atonce category:"Touring companys"; 
	parameter "Probability of hiking to secondary targets [1]" var:tc_probability_to_add_additional_targets category:"Touring companys";   
	parameter "Max aerial distance of secondary targets [m]" var:max_additional_poi_aerial_distance category:"Touring companys";
	parameter "Lower value close to nature ways weights [1]" var:usage_percent_category_lower category:"Touring companys";
	parameter "Upper value close to nature ways weights [1]" var:usage_percent_category_upper category:"Touring companys";

	parameter "Shortest path algorithm:" var:shortest_path_algorithm category:"Ways";
	parameter "Simulaton year type:" var:simulation_year category:"Ways";
	parameter "Probability of starting a winter-period:" var:proba_winter_period category:"Ways";
	parameter "Mean days of a winter-period:" var:winter_period_mean category:"Ways";
	parameter "halfrange days of a winter-period:" var:winter_period_halfrange category:"Ways";

	parameter "Weather factor weighted list:" var:weather_factor_weighted_list category:"Environment";
	parameter "Weather factors list:" var:weather_factors_list category:"Environment";
	parameter "Weather smooting value:" var:factor_weather_smoothing_value category:"Environment";
	parameter "Weekend over weekday factor:" var:factor_weekday_value category:"Environment";
	parameter "Holidays factor:" var:factor_holiday_value category:"Environment";

	parameter "First simulated day of year:" var:start_simuation_at_day category:"Simulation";
	parameter "Pause condition:" var:pause_condition category:"Simulation";
	parameter "Pause condition value:" var:pause_condition_value category: "Simulation";
	parameter "Save periodical KPIs:" var:save_periodical_files category:"Statistics & Exports";
	parameter "Save parameter summary (start):" var:save_parameter_summary category:"Statistics & Exports";
	parameter "Save value summary (end):" var:save_values_summary category:"Statistics & Exports";
	parameter "Save species summary (end):" var:save_species_summarys category:"Statistics & Exports";
	parameter "Use exportfile identifier:" var:use_actualdatetimestring category:"Statistics & Exports";

	parameter "DISPLAY tc:" var:display_tc category:"Map tc";
	parameter "DISPLAY tc was also inside nlp:" var:display_inside_nlp category:"Map tc";
	parameter "DISPLAY tc was only outside nlp:" var:display_outside_nlp category:"Map tc";
	parameter "DISPLAY tc destinationtype:" var:display_tc_destinationtype category:"Map tc";
	parameter "DISPLAY tc starttype:" var:display_tc_starttype category:"Map tc";
	parameter "SHOW tc line to target:" var:show_linetotarget category:"Map tc";

	parameter "DISPLAY areas" var:display_areas category:"Map areas";
	parameter "DISPLAY heatmap (and no areas)" var:display_heatmap category:"Map areas";
	parameter "colorizing min perc. (heatm.,areas)" var:colorizing_min_perc category:"Map areas";
	parameter "SHOW perc. (heatm, areas)" var:show_percentage_area category:"Map areas";

	parameter "SHOW tc IDs:" var:show_tc_id category:"Map IDs";
	parameter "SHOW POI IDs" var:show_poi_id category:"Map IDs";
	parameter "SHOW parking-area IDs" var:show_parking_id category:"Map IDs";
	parameter "SHOW bus-stops IDs" var:show_bus_id category:"Map IDs";
	parameter "SHOW town IDs" var:show_town_id category:"Map IDs";
	parameter "SHOW counting IDs" var:show_counting_id category:"Map IDs";


	// ---------------------------------------------------------------------------------------
	// ouputs
	// ---------------------------------------------------------------------------------------
	output {

		display name:"Execution" refresh:every(date_cycles_per_simulation_day) {
			chart
				name:"Program execution time total"
				type:series
				size:{1.00,0.50}
				position:{0.00,0.00}
				style:area
				x_label:"Days"
				y_label:"Time [s]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "time [s]" value:int((machine_time - t0)/1000) color:#darkred;
			}
			chart
				name:"Program execution time daily"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.50}
				x_label:"Days"
				y_label:"Time [s]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "time [s]" value:(t3-t2)/1000 color:#darkred;
			}
			chart
				name:"Avg. Program execution time per tc daily"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.75}
				x_label:"Days"
				y_label:"Time [s]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "time [s]" value:tc_total>0 ? ((machine_time - t0)/1000)/tc_total : 0 color:#darkred;
			}
		}

		display name:"Init_TC" refresh:every(date_cycles_per_simulation_day) {
			chart
				name:"Number of starting touring companies"
				type:series
				size:{1.00,0.33}
				position:{0.00,0.00}
				style:step
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "(total)" value:tc count (each.name != nil) * modeling_reduction_factor color:#gray;
					data "start parking" value:tc count(each.tc_starttype = 'parking') * modeling_reduction_factor color:parking_color;
					data "start bus" value:tc count(each.tc_starttype = 'bus') * modeling_reduction_factor color:bus_color;
					data "start town" value:tc count(each.tc_starttype = 'town') * modeling_reduction_factor color:town_color;
					data "start train_train" value:tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train') * modeling_reduction_factor color:train_train_color;
					data "start train_valley" value:tc count(each.tc_starttype = 'train'and each.tc_startsubtype = 'bytrain_valley') * modeling_reduction_factor color:train_valley_color;
					data "nospace" value:tc count (each.tc_status = 'nospace') * modeling_reduction_factor color:tc_color_nospace;
					data "notarget" value:tc count (each.tc_status = 'notarget') * modeling_reduction_factor color:tc_color_notarget;
					loop dl over:tc_destinationtype_list {
						data dl value:tc count (each.tc_destinationtype = dl) * modeling_reduction_factor;
					} 
			}
			chart
				name:"Factors for starting touring companies"
				type:series
				size:{1.00,0.33}
				position:{0.00,0.33}
				style:step
				x_label:"Days"
				y_label:"Factor [1]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "(total)" value:calc_factor_parking+calc_factor_bus+calc_factor_town+calc_factor_train color:#gray;
					data "factor parking" value:calc_factor_parking color:parking_color;
					data "factor bus" value:calc_factor_bus color:bus_color;
					data "factor town" value:calc_factor_town color:town_color;
					data "factor train" value:calc_factor_train color:train_train_color;
			}
			chart
				name:"Factors"
				type:series
				size:{1.00,0.33}
				position:{0.00,0.66}
				style:step
				x_label:"Days"
				y_label:"Factor [1]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "factor weather (calc)" value:calc_factor_weather color:#black;
					data "factor hikingspeed by weather" value:weather_hikingspeed_today_factor color:#lightblue;
					data "factor weekday" value:factor_weekday color:#green;
					data "factor season" value:factor_season color:#blue;
					data "factor holiday" value:factor_holiday color:#red;
			}
		}

		display name:"Seasons" refresh:every(date_cycles_per_simulation_day) {
			chart
				name:"Season information"
				type:series
				size:{1.00,0.33}
				position:{0.00,0.00}
				style:step
				x_label:"Days"
				y_label:""
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "possible winter" value:possible_winter color:#darkgray;
					data "remaining_winter_days" value:remaining_winter_days color:#darkblue;
			}
		}

		display name:"Totals1" refresh:every(date_cycles_per_simulation_day) {
			chart
				name:"Total touring companies quantity by desttype"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.00}
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "desttype target" value:total_tc_desttype_target*modeling_reduction_factor;
					data "desttype nature" value:total_tc_desttype_nature*modeling_reduction_factor;
					data "desttype hwn" value:total_tc_desttype_hwn*modeling_reduction_factor;
			}
			chart
				name:"Total hikers (tc members) quantity by desttype"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.25}
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "desttype target" value:total_tc_mb_desttype_target*modeling_reduction_factor;
					data "desttype nature" value:total_tc_mb_desttype_nature*modeling_reduction_factor;
					data "desttype hwn" value:total_tc_mb_desttype_hwn*modeling_reduction_factor;
			}
			chart
				name:"Total touring companies quantity by starttype"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.50}
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "start parking" value:total_tc_parking*modeling_reduction_factor color:parking_color;
					data "start bus" value:total_tc_bus*modeling_reduction_factor color:bus_color;
					data "start town" value:total_tc_town*modeling_reduction_factor color:town_color;
					data "start train_train" value:total_tc_train_train*modeling_reduction_factor color:train_train_color;
					data "start train_valley" value:total_tc_train_valley*modeling_reduction_factor color:train_valley_color;
					data "nospace" value:total_tc_nospace*modeling_reduction_factor color:tc_color_nospace;
					data "notarget" value:total_tc_notarget*modeling_reduction_factor color:tc_color_notarget;
					data "late" value:total_tc_late*modeling_reduction_factor color:tc_color_late;
					data "distancebudget" value:total_tc_distancebudget*modeling_reduction_factor color:tc_color_distancebudget;
			}
			chart
				name:"Total hikers (tc members) quantity by starttype"
				type:series
				style:step
				size:{1.00,0.25}
				position:{0.00,0.75}
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "start parking" value:total_tc_mb_parking*modeling_reduction_factor color:parking_color;
					data "start bus" value:total_tc_mb_bus*modeling_reduction_factor color:bus_color;
					data "start town" value:total_tc_mb_town*modeling_reduction_factor color:town_color;
					data "start train_train" value:total_tc_mb_train_train*modeling_reduction_factor color:train_train_color;
					data "start train_valley" value:total_tc_mb_train_valley*modeling_reduction_factor color:train_valley_color;
					data "nospace" value:total_tc_mb_nospace*modeling_reduction_factor color:tc_color_nospace;
					data "notarget" value:total_tc_mb_notarget*modeling_reduction_factor color:tc_color_notarget;
					data "late" value:total_tc_mb_late*modeling_reduction_factor color:tc_color_late;
					data "distancebudget" value:total_tc_mb_distancebudget*modeling_reduction_factor color:tc_color_distancebudget;
			}
		}

		display name:"Totals2" refresh:every(date_cycles_per_simulation_day-1) {
			chart
				name:"Total sum of touring companies"
				type:series
				style:step
				size:{1.00,0.33}
				position:{0.00,0.00}
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "tc total" value:tc_total_last*modeling_reduction_factor color:#dimgray;
					data "tc NLP total" value:tc_total_nlp*modeling_reduction_factor color:#red;
					data "tc OUTSIDE total" value:tc_total_outside*modeling_reduction_factor color:#blue;
			}
			chart
				name:"Total sum of hikers (tc members)"
				type:series
				style:step
				size:{1.00,0.33}
				position:{0.00,0.33}
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "mb total" value:mb_total_last*modeling_reduction_factor color:#dimgray;
					data "mb NLP total" value:mb_total_nlp*modeling_reduction_factor color:#red;
					data "mb OUTSIDE total" value:mb_total_outside*modeling_reduction_factor color:#blue;
			}
			chart
				name:"Total hikers (tc members) nospace / notarget / late"
				type:series
				style:step
				size:{1.00,0.33}
				position:{0.00,0.66}
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "mb (total) nospace" value:total_tc_mb_nospace*modeling_reduction_factor color:tc_color_nospace;
					data "mb (total) notarget" value:total_tc_mb_notarget*modeling_reduction_factor color:tc_color_notarget;
					data "mb (total) late" value:total_tc_mb_late*modeling_reduction_factor color:tc_color_late;
			}
		}

		display name:"Calibration" refresh:every(date_cycles_per_simulation_day-1) {
			chart
				name:"CALIBRATION: factors (1)"
				type:series
				style:step
				size:{1.00,0.33}
				position:{0.00,0.00}
				x_label:"Days"
				y_label:"Factor [1]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "Factor Brocken mb by train" value:(ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))>0 ? int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000 : 0 color:#red;
			}
			chart
				name:"CALIBRATION: factors (2)"
				type:series
				style:step
				size:{1.00,0.33}
				position:{0.00,0.33}
				x_label:"Days"
				y_label:"Factor [1]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "???factor bus-stops" value:(total_tc_mb_parking+total_tc_mb_nospace)>0 ? int(10000*total_tc_mb_bus/(total_tc_mb_parking+total_tc_mb_nospace))/10000 : 0 color:bus_color;
					data "???factor towns" value:(total_tc_mb_parking+total_tc_mb_nospace)>0 ? int(10000*total_tc_mb_town/(total_tc_mb_parking+total_tc_mb_nospace))/10000 : 0 color:town_color;
					data "???factor train" value:(total_tc_mb_parking+total_tc_mb_nospace)>0 ? int(10000*(total_tc_mb_train_train+total_tc_mb_train_valley)/(total_tc_mb_parking+total_tc_mb_nospace))/10000 : 0 color:train_train_color;
			}
			chart
				name:"CALIBRATION: total starttype percentages (tc members)"
				type:pie
				size:{0.50,0.33}
				position:{0.00,0.66}
				style:ring
				{
					data "parking(+stopover)" value:total_tc_mb_parking*modeling_reduction_factor color:parking_color;
					data "bus-stops" value:total_tc_mb_bus*modeling_reduction_factor color:bus_color;
					data "towns" value:total_tc_mb_town*modeling_reduction_factor color:town_color;
					data "bytrain_train" value:total_tc_mb_train_train*modeling_reduction_factor color:train_train_color;
					data "bytrain_valley" value:total_tc_mb_train_valley*modeling_reduction_factor color:train_valley_color;
					data "nospace" value:total_tc_mb_nospace*modeling_reduction_factor color:tc_color_nospace;
			}
			chart
				name:"CALIBRATION: avg. hikers (tc members) per touring company"
				type:series
				style:step
				size:{0.50,0.33}
				position:{0.50,0.66}
				x_label:"Days"
				y_label:"Hikers (tc members) per tc [pcs]"
				x_range:[1,370]
				x_serie_labels:xaxis_oneyear
				{
					data "avg. mb per tc" value:tc_total>0 ? mb_total/tc_total : 0 color:#black;
			}
		}

		display name:"Status" refresh:every(refresh_chart_every) {
			chart
				name:"tc: actual status"
				type:series
				style:area
				size:{1.00,0.33}
				position:{0.00,0.00}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				{
					data "hikingtarget" value:	(tc count (each.tc_status = 'hikingtarget')
																				+ 0
																			)* modeling_reduction_factor color:tc_color_hikingtarget;
					data "target" value:				(tc count (each.tc_status = 'target')
																				+ tc count (each.tc_status = 'hikingtarget')
																			)* modeling_reduction_factor color:tc_color_target;
					data "hikinghome" value:		(tc count (each.tc_status = 'hikinghome')
																				+ tc count (each.tc_status = 'target')+tc count (each.tc_status = 'hikingtarget')
																			)* modeling_reduction_factor color:tc_color_hikinghome;
					data "home" value:					(tc count (each.tc_status = 'home')
																				+ tc count (each.tc_status = 'hikinghome')+tc count (each.tc_status = 'target')+tc count (each.tc_status = 'hikingtarget')
																			)* modeling_reduction_factor color:tc_color_home;
			}
			chart
				name:"tc: starting this cycle"
				type:series
				style:area
				size:{1.00,0.33}
				position:{0.00,0.33}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				{
					data "start parking" value:			(tc count(each.tc_starttype = 'parking' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																						+ (0)
																					)* modeling_reduction_factor color:parking_color;
					data "start bus" value:					(tc count(each.tc_starttype = 'bus' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																						+ tc count(each.tc_starttype = 'parking' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																					)* modeling_reduction_factor  color:bus_color;
					data "start town" value:				(tc count(each.tc_starttype = 'town' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																						+ tc count(each.tc_starttype = 'bus' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)) + tc count(each.tc_starttype = 'parking' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																					)* modeling_reduction_factor  color:town_color;
					data "start train_train" value:	(tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																						+ tc count(each.tc_starttype = 'town' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)) + tc count(each.tc_starttype = 'bus' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day) + tc count(each.tc_starttype = 'parking' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)))
																					)*modeling_reduction_factor  color:train_train_color;
					data "start train_valley" value:(	tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_valley' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																						+ tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)) + tc count(each.tc_starttype = 'town' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)) + tc count(each.tc_starttype = 'bus' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day)) + tc count(each.tc_starttype = 'parking' and each.tc_startcycle = mod(cycle,date_cycles_per_simulation_day))
																					)* modeling_reduction_factor  color:train_valley_color;
			}
			chart
				name:"tc: active or waiting to start"
				type:series
				style:area
				size:{1.00,0.33}
				position:{0.00,0.66}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"Touring companies [pcs]"
				{
					data "start parking" value:			(tc count(each.tc_starttype = 'parking')
																						+ (0)
																					)* modeling_reduction_factor color:parking_color;
					data "start bus" value:					(tc count(each.tc_starttype = 'bus')
																						+ tc count(each.tc_starttype = 'parking')
																					)* modeling_reduction_factor color:bus_color;
					data "start town" value:				(tc count(each.tc_starttype = 'town')
																						+ tc count(each.tc_starttype = 'bus') + tc count(each.tc_starttype = 'parking')
																					)* modeling_reduction_factor color:town_color;
					data "start train_train" value:	(tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train')
																						+ tc count(each.tc_starttype = 'town') + tc count(each.tc_starttype = 'bus') + tc count(each.tc_starttype = 'parking')
																					)* modeling_reduction_factor color:train_train_color;
					data "start train_valley" value:(tc count(each.tc_starttype = 'train'and each.tc_startsubtype = 'bytrain_valley')
																						+ tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train') + tc count(each.tc_starttype = 'town') + tc count(each.tc_starttype = 'bus') + tc count(each.tc_starttype = 'parking')
																					)* modeling_reduction_factor color:train_valley_color;
			}
		}

		display name:"Counts" refresh:every(refresh_chart_every) {
			chart
				name:"members: ca" 
				type:series
				style:step
				size:{1.00,0.50}
				position:{0.00,0.00}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				{
					loop c over:ca {
						data c.name value:c.tc_members_in_area*modeling_reduction_factor;
					}
			}
			chart
				name:"members: cp" 
				type:series
				style:step
				size:{1.00,0.50}
				position:{0.00,0.50}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"Hikers (tc members) [pcs]"
				{
					loop c over:cp {
						if (c.shape_subpoint = 1) {
							data c.name value:c.tc_members_at_cp*modeling_reduction_factor;
						}
					}
			}
		}

		display name:"Distributions" refresh:every(refresh_chart_every) {
			chart
				name:"tc: members"
 				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.00,0.00}
				y_range: [0,int(total_standard_number_of_tc/modeling_reduction_factor*2.0)]
				{
					datalist distribution_tc_members at "legend" value:distribution_tc_members at "values" color:#gray;
			}
			chart
				name:"tc: max hiking distance"
				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.50,0.00}
				y_range: [0,total_standard_number_of_tc/modeling_reduction_factor*0.7]
				{
					datalist distribution_tc_max_hiking_distance at "legend" value: distribution_tc_max_hiking_distance at "values" color:#gray;
			}
			chart
				name:"tc: startcycles"
				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.00,0.33}
				y_range: [0,total_standard_number_of_tc/modeling_reduction_factor*1.0]
				{
					datalist distribution_tc_startcycle at "legend" value: distribution_tc_startcycle at "values" color:#gray;
			}
			chart
				name:"tc: resting-at-target cycles"
				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.50,0.33}
				y_range: [0,total_standard_number_of_tc/modeling_reduction_factor*1.0]
				{
					datalist distribution_tc_restingattarget_cycles at "legend" value: distribution_tc_restingattarget_cycles at "values" color:#gray;
			}
			chart
				name:"tc: destination types"
				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.00,0.66}
				y_range: [0,total_standard_number_of_tc/modeling_reduction_factor*3]
				{
				loop dl over:tc_destinationtype_list {
					data dl value:tc count (each.tc_destinationtype = dl);
				} 
			}
			chart
				name:"tc: status"
				type:histogram
				background:rgb(235,235,235,255)
				size:{0.50,0.33}
				position:{0.50,0.66}
				y_range: [0,total_standard_number_of_tc/modeling_reduction_factor*2.5]
				{
					data "setup" value:tc count (each.tc_status = 'setup') color:tc_color_setup;
					data "hikingtarget" value:tc count (each.tc_status = 'hikingtarget') color:tc_color_hikingtarget;
					data "target" value:tc count (each.tc_status = 'target') color:tc_color_target;
					data "hikinghome" value:tc count (each.tc_status = 'hikinghome') color:tc_color_hikinghome;
					data "home" value:tc count (each.tc_status = 'home') color:tc_color_home;
					data "nospace" value:tc count (each.tc_status = 'nospace') color:tc_color_nospace;
					data "notarget" value:tc count (each.tc_status = 'notarget') color:tc_color_notarget;
			}
		}

		display name:"Home" refresh:every(refresh_chart_every) {
			chart
				name:"tc@home sum parking (cars)" 
				type:series
				style:area
				size:{1.00,0.50}
				position:{0.00,0.00}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"tc (=cars) [pcs]"
				{
					data "total tc (=cars)" value:sum(parking collect (each.tc_home_now*modeling_reduction_factor));
				}
			chart
				name:"tc@home parking-areas" 
				type:series
				style:step
				size:{1.00,0.50}
				position:{0.00,0.50}
				x_range: date_cycles_per_simulation_day * 7
				x_tick_unit: date_cycles_per_simulation_day
				x_serie_labels: cycle=0 ? 0 : int(cycle/date_cycles_per_simulation_day+1)
				x_label:"Days"
				y_label:"tc (=cars) [pcs]"
				{
					loop p over:parking {
						data p.name value:p.tc_home_now*modeling_reduction_factor;
					}
				}
		}

		display name:"M A P" refresh:every(refresh_map_every) type:opengl {
			species heatmap aspect:draw_heatmap refresh:true;
			species ca aspect:draw_ca_Revier refresh:true;
			species ca aspect:draw_ca_Bereich refresh:true;
			species nlp aspect:draw_nlp refresh:true;
			species street aspect:draw_street refresh:true;
			species railway aspect:draw_railway refresh:true;
			species parking aspect:draw_parking refresh:true;
			species bus aspect:draw_bus refresh:true;
			species towns aspect:draw_towns refresh:true;
			species train aspect:draw_train refresh:true;
			species pois aspect:draw_pois refresh:true;
			species ways aspect:draw_ways refresh:true;
			species cp aspect:draw_cp refresh:true;
			species tc aspect:draw_tc refresh:true;
		}

		// standard monitors
		monitor name:"STANDARD MONITORS" value:'' color:#black;
		monitor name:"Execution time [s]" value:int((machine_time - t0)/1000) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"Simulation date (calculated)" value:date_calculated color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"Years infos (CSV)" value:years_infos_infostring color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Cycle of this day" value:mod(cycle,date_cycles_per_simulation_day) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"startcycle (min,mean,max)" value:string(min(list_tc_startcycle))+" / "+string(mean(list_tc_startcycle) with_precision 2)+" / "+string(max(list_tc_startcycle)) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Execution time per tc [s]" value:int((machine_time - t0)/1000/tc_total*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Modeling reduction factor" value:int(10000*modeling_reduction_factor)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Identification" value:identification color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"BUGFIXMODE" value:BUGFIXMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"FIXEDQUANTITIES" value:FIXEDQUANTITIES color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"EQUALATTRACTIONSMODE" value:EQUALATTRACTIONSMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"EQUALWEIGHTS" value:EQUALWEIGHTS color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"DRYRUNMODE" value:DRYRUNMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVATEWINTER" value:ACTIVATEWINTER color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVATESUMMER" value:ACTIVATESUMMER color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVITYWINTERDAYS" value:ACTIVITYWINTERDAYS color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"numberofwinterdays" value:numberofwinterdays color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Set season_type" value:set_season_type color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Possible_winter" value:possible_winter color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Remaining_winter_days" value:remaining_winter_days color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"total winter days" value:int(total_winter_days) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Shortest path algorithm" value:shortest_path_algorithm color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);

		// calibration monitors (1)
		monitor name:"CALIBRARTION MONITORS (NO reduction)" value:'' color:#black;
		monitor name:"12   avg. mb per tc" value:int(mb_total/tc_total*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     factor tc bus" value:int(10000*total_tc_bus/total_tc_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"07   factor mb bus" value:int(10000*total_tc_mb_bus/total_tc_mb_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     factor tc town" value:int(10000*total_tc_town/total_tc_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"08   factor mb town" value:int(10000*total_tc_mb_town/total_tc_mb_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"     mb total" value:int(mb_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"01      NLP total" value:int(mb_total_nlp*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        mb OUTSIDE total" value:int(mb_total_outside*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"20   Brocken mb count cp1" value:int(cp[20].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Brocken mb count cp2" value:int(cp[20].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Brocken mb count ca" value:int(ca[0].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"03      Brocken mb train" value:int((total_tc_mb_train_train+total_tc_mb_train_valley)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Brocken mb hiking cp1" value:int((cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Brocken mb hiking ca" value:int((ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"06      Factor Brocken mb t/h cp1" value:int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Brocken mb t/h ca" value:int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"27      Factor Brocken mb of NLP cp1" value:int(int(cp[20].sum_tc_members_heading_dir1)/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
 		monitor name:"        Factor Brocken mb of NLP ca" value:int(ca[0].count_tc_members_hiked_area_once/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"21   Torfhaus mb hiked cp1+cp2" value:int(2*(0.5*cp[24].sum_tc_members_heading_dir1+0.5*cp[26].sum_tc_members_heading_dir1)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Torfhaus mb hiked ca" value:int(ca[12].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"28      Factor Torfhaus mb of NLP cp1+cp2" value:int(2*(0.5*cp[24].sum_tc_members_heading_dir1+0.5*cp[26].sum_tc_members_heading_dir1)/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Torfhaus mb of NLP ca" value:int(ca[12].count_tc_members_hiked_area_once/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"23   Rabenklippe mb hiked cp12" value:int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Rabenkl./Luchs. mb hiked ca" value:int(ca[3].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"30      Factor Rabenklippe mb of NLP cp12" value:int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Rabenklippe mb of NLP ca" value:int(ca[3].count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"24   Scharfenstein mb hiked cp1" value:int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Scharfenstein mb hiked ca" value:int(ca[2].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"31      Factor Scharfenstein mb of NLP cp1" value:int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Scharfenstein mb of NLP ca" value:int(ca[2].count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"22   Drei-Annen-Hohne mb hiked cp1" value:int(cp[22].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"29      Factor Drei-Annen-Hohne mb of NLP cp1" value:int(cp[22].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"25   Zantierplatz mb hiked cp1" value:int(cp[10].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"32      Factor Zantierplatz mb of NLP cp1" value:int(cp[10].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"26   Bwpf. mb POI" value:int(pois[79].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Bwpf. mb" value:int(pois[79].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"40   Luchsg. mb POI" value:int(pois[65].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Luchsg. mb" value:int(pois[65].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"41   Brockengar. mb POI" value:int(pois[66].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Brockengar. mb" value:int(pois[66].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"42   NLP Brocken mb POI" value:int(pois[63].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Brocken mb" value:int(pois[63].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"43   NLP Torfhaus mb POI" value:int(pois[58].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Torfhaus mb" value:int(pois[58].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"44   NLP Hohnehof mb POI" value:int(pois[64].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Hohnehof mb" value:int(pois[64].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"45   NLP Ilsetal mb POI" value:int(pois[60].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Ilsetal mb" value:int(pois[60].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"46   NLP Schierke mb POI" value:int(pois[62].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Schierke mb" value:int(pois[62].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"47   NLP B.Hbg. mb POI" value:int(pois[56].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP B.Hbg. mb" value:int(pois[56].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"48   NLP Schst. mb POI" value:int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Schst. mb" value:int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"60   CP1%(ZG) (Goetheweg)" value:int(cp[0].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP1(d1) (Goetheweg)" value:int(cp[0].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP1(d2) (Goetheweg)" value:int(cp[0].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"61   CP2%(ZG) (Str. mitte)" value:int(cp[1].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP2(d1) (Str. mitte)" value:int(cp[1].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP2(d2) (Str. mitte)" value:int(cp[1].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"62   CP3%(ZG) (Hirtenstieg)" value:int(cp[2].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP3(d1) (Hirtenstieg)" value:int(cp[2].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP3(d2) (Hirtenstieg)" value:int(cp[2].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"63   CP4%(ZG) (Str. oben)" value:int(cp[3].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP4(d1) (Str. oben)" value:int(cp[3].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP4(d2) (Str. oben)" value:int(cp[3].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"64   CP15%(ZG) (Eckerloch)" value:int(cp[28].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP15(d1) (Eckerloch)" value:int(cp[28].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP15(d2) (Eckerloch)" value:int(cp[28].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"65   CP16%(ZG) (Str. unten)" value:int(cp[30].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP16(d1) (Str. unten)" value:int(cp[30].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     CP16(d2) (Str. unten)" value:int(cp[30].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"80   Bad Harzburg (Brocken) %" value:int(count_brocken_members_percent_BADHARZBURG*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"81   Torfhaus (Brocken) %" value:int(count_brocken_members_percent_TORFHAUS*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"82   Oderbrück (Brocken) %" value:int(count_brocken_members_percent_ODERBRUECK*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"83   Braunlage (Brocken) %" value:int(count_brocken_members_percent_BRAUNLAGE*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"84   Schierke (Brocken) %" value:int(count_brocken_members_percent_SCHIERKE*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"85   Drei-Annen-Hohne (Brocken) %" value:int(count_brocken_members_percent_DREIANNENHOHNE*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"86   Ilsenburg (Brocken) %" value:int(count_brocken_members_percent_ILSENBURG*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		// (total) monitors
		monitor name:"TOTAL MONITORS (NO reduction)" value:'' color:#black;
		monitor name:"mb (total)" value:int(mb_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) parking-areas" value:int(total_tc_mb_parking*modeling_reduction_factor) color:parking_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bus-stops" value:int(total_tc_mb_bus*modeling_reduction_factor) color:bus_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) towns" value:int(total_tc_mb_town*modeling_reduction_factor) color:town_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bytrain_train" value:int(total_tc_mb_train_train*modeling_reduction_factor) color:train_train_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bytrain_valley" value:int(total_tc_mb_train_valley*modeling_reduction_factor) color:train_valley_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) nospace" value:int(total_tc_mb_nospace*modeling_reduction_factor) color:tc_color_nospace refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) notarget]" value:int(total_tc_mb_notarget*modeling_reduction_factor) color:tc_color_notarget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) late]" value:int(total_tc_mb_late*modeling_reduction_factor) color:tc_color_late refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) distancebudget]" value:int(total_tc_mb_distancebudget*modeling_reduction_factor) color:tc_color_distancebudget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) target" value:int(total_tc_mb_desttype_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) nature" value:int(total_tc_mb_desttype_nature*modeling_reduction_factor)color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) hwn" value:int(total_tc_mb_desttype_hwn*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"tc (total)" value:int(tc_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) parking-areas" value:int(total_tc_parking*modeling_reduction_factor) color:parking_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bus-stops" value:int(total_tc_bus*modeling_reduction_factor) color:bus_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) towns" value:int(total_tc_town*modeling_reduction_factor) color:town_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bytrain_train" value:int(total_tc_train_train*modeling_reduction_factor) color:train_train_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bytrain_valley" value:int(total_tc_train_valley*modeling_reduction_factor) color:train_valley_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) nospace" value:int(total_tc_nospace*modeling_reduction_factor) color:tc_color_nospace refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) notarget]" value:int(total_tc_notarget*modeling_reduction_factor) color:tc_color_notarget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) late]" value:int(total_tc_late*modeling_reduction_factor) color:tc_color_late refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) distancebudget]" value:int(total_tc_distancebudget*modeling_reduction_factor) color:tc_color_distancebudget refresh:every(date_cycles_per_simulation_day-1);

		// (actual) monitors
		monitor name:"ACTUAL MONITORS (WITH reduction)" value:'' color:#black;
		monitor name:"tc" value:tc count(each.name != nil) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"  tc status setup" value:tc count(each.tc_status = 'setup') color:tc_color_setup refresh:every(refresh_monitor_every);
		monitor name:"  tc status hikingtarget" value:tc count(each.tc_status = 'hikingtarget') color:tc_color_hikingtarget refresh:every(refresh_monitor_every);
		monitor name:"  tc status target" value:tc count(each.tc_status = 'target') color:tc_color_target refresh:every(refresh_monitor_every);
		monitor name:"  tc status hikinghome" value:tc count(each.tc_status = 'hikinghome') color:tc_color_hikinghome refresh:every(refresh_monitor_every);
		monitor name:"  tc status home" value:tc count(each.tc_status = 'home') color:tc_color_home refresh:every(refresh_monitor_every);
		monitor name:"  tc status nospace" value:tc count(each.tc_status = 'nospace') color:tc_color_nospace refresh:every(refresh_monitor_every);
		monitor name:"    [tc status notarget]" value:tc count(each.tc_status = 'notarget') color:tc_color_notarget refresh:every(refresh_monitor_every);
		monitor name:"  tc starting parking-areas" value:tc count(each.tc_starttype = 'parking') color:parking_color refresh:every(refresh_monitor_every);
		monitor name:"  tc starting bus-stops" value:tc count(each.tc_starttype = 'bus') color:bus_color refresh:every(refresh_monitor_every);
		monitor name:"  tc starting towns" value:tc count(each.tc_starttype = 'town') color:town_color refresh:every(refresh_monitor_every);
		monitor name:"  tc starting bytrain_train" value:tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_train') color:train_train_color refresh:every(refresh_monitor_every);
		monitor name:"  tc starting bytrain_valley" value:tc count(each.tc_starttype = 'train' and each.tc_startsubtype = 'bytrain_valley') color:train_valley_color refresh:every(refresh_monitor_every);
		monitor name:"mb" value:sum(list_tc_members) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);

		// model operating values
		monitor name:"MODEL OPERATING VALUES (WITH reduction)" value:'' color:#black;
		monitor name:"add poi added" value:total_additional_poi_added color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"    add restaurant added" value:total_additional_restaurant_added color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"more than 2 cp" value:total_morethan2cp color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"nil path" value:total_nilpath color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);

	}


	// ---------------------------------------------------------------------------------------
	// several actions for giving summaries on the commandline of all species
	// ---------------------------------------------------------------------------------------
	action summarize_ways {
		loop i from: 0 to: (length(ways)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + ways[i].shape_objectid
				+ ", name=" + ways[i].name
				+ ", cat=" + ways[i].shape_way_category
				+ ", nature=" + ways[i].shape_way_nature
				+ ", diff_sum=" + ways[i].way_difficulty_factor_summer
				+ ", diff_win=" + ways[i].way_difficulty_factor_winter
				+ ", count_tc_hiked_way=" + ways[i].count_tc_hiked_way
				+ ", count_tc_members_hiked_way=" + ways[i].count_tc_members_hiked_way
				+ ", count_tc_nature_hiked_way=" + ways[i].count_tc_nature_hiked_way
				+ ", count_tc_members_nature_hiked_way=" + ways[i].count_tc_members_nature_hiked_way
				+ ", usage_percent=" + ways[i].usage_percent;
		}
	}

	action summarize_parking {
		loop i from: 0 to: (length(parking)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + parking[i].shape_objectid
				+ ", name=" + parking[i].name
				+ ", attraction=" + parking[i].shape_attraction
				+ ", capacity=" + parking[i].shape_capacity
				+ ", sum_tc_home=" + parking[i].sum_tc_home
				+ ", sum_tc_members_home=" + parking[i].sum_tc_members_home
				+ ", sum_tc_BROCKEN=" + parking[i].sum_tc_BROCKEN
				+ ", sum_tc_members_BROCKEN=" + parking[i].sum_tc_members_BROCKEN;
		}
	}

	action summarize_bus {
		loop i from: 0 to: (length(bus)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + bus[i].shape_objectid
				+ ", name=" + bus[i].name
				+ ", attraction=" + bus[i].shape_attraction
				+ ", sum_tc_home=" + bus[i].sum_tc_home
				+ ", sum_tc_members_home=" + bus[i].sum_tc_members_home
				+ ", sum_tc_BROCKEN=" + bus[i].sum_tc_BROCKEN
				+ ", sum_tc_members_BROCKEN=" + bus[i].sum_tc_members_BROCKEN;
		}
	}

	action summarize_towns {
		loop i from: 0 to: (length(towns)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + towns[i].shape_objectid
				+ ", name=" + towns[i].name
				+ ", attraction=" + towns[i].shape_attraction
				+ ", sum_tc_home=" + towns[i].sum_tc_home
				+ ", sum_tc_members_home=" + towns[i].sum_tc_members_home
				+ ", sum_tc_BROCKEN=" + towns[i].sum_tc_BROCKEN
				+ ", sum_tc_members_BROCKEN=" + towns[i].sum_tc_members_BROCKEN;
		}
	}

	action summarize_train {
		loop i from: 0 to: (length(train)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + train[i].shape_objectid
				+ ", name=" + train[i].name
				+ ", attraction=" + train[i].shape_attraction
				+ ", sum_tc_home=" + train[i].sum_tc_home
				+ ", sum_tc_members_home=" + train[i].sum_tc_members_home;
		}
	}

	action summarize_pois {
		loop i from: 0 to: (length(pois)-1) {
			write "i=" + string(i)
				+ " --> objectid=" + pois[i].shape_objectid
				+ ", name=" + pois[i].name
				+ ", attraction=" + pois[i].shape_attraction
				+ ", attraction_add=" + pois[i].shape_attraction_add
				+ ", primary=" + pois[i].shape_primary
				+ ", tc_at_target=" + pois[i].tc_at_target
				+ ", tc_members_at_target=" + pois[i].tc_members_at_target
				+ ", tc_nature_at_target=" + pois[i].tc_nature_at_target
				+ ", tc_members_nature_at_target=" + pois[i].tc_members_nature_at_target
				+ ", tc_BROCKEN_at_target=" + pois[i].tc_BROCKEN_at_target
				+ ", tc_members_BROCKEN_at_target=" + pois[i].tc_members_BROCKEN_at_target;
		}
	}

	action summarize_ca {
		loop i from: 0 to: (length(ca)-1) {
			write "(i=" + string(i)
				+ ") --> objectid=" + ca[i].shape_objectid
				+ ", name=" + ca[i].name
				+ ", count_tc_hiked_area=" + ca[i].count_tc_hiked_area
				+ ", count_tc_members_hiked_area=" + ca[i].count_tc_members_hiked_area
				+ ", count_tc_members_hiked_area_once=" + ca[i].count_tc_members_hiked_area_once;
		}
	}

	action summarize_cp {
		loop i from: 0 to: (length(cp)-1) {
			if (cp[i].shape_subpoint = 1) {
				write "(i=" + string(i)
					+ ") --> objectid=" + cp[i].shape_objectid
					+ ", name=" + cp[i].name
					+ ", cp/subpoint: " + cp[i].shape_cp
					+ "/"  + cp[i].shape_subpoint
					+ " sum_tc_at_cp=" + string(cp[i].sum_tc_at_cp)
					+ ", sum_tc_heading_dir1=" + cp[i].sum_tc_heading_dir1
					+ ", sum_tc_heading_dir2=" + cp[i].sum_tc_heading_dir2;
			}
		}
	}

	action summarize_heatmap {
		loop i from: 0 to: (length(heatmap)-1) {
			write "(i=" + string(i)
				+ ") --> objectid=" + heatmap[i].shape_id
				+ ", name=" + heatmap[i].name
				+ ", count_tc_hiked_heatmap=" + heatmap[i].count_tc_hiked_heatmap
				+ ", count_tc_members_hiked_heatmap=" + heatmap[i].count_tc_members_hiked_heatmap;
		}
	}


	// ---------------------------------------------------------------------------------------
	// write specific shortest paths combinations
	// please uncomment the type output needed
	// ---------------------------------------------------------------------------------------
	action write_all_shortest_paths {
		loop src over:parking {
			loop dst over:pois_primary {
				path shortest_path <- path_between (ways_graph,src,dst);
				float aerial_distance <- src distance_to dst;
				float path_distance <- src distance_to dst using topology(ways_graph);
//				if (dst.name = "ID-46: Aussichtspunkt Brocken") { write "PARKING;" + src.name + ";" + dst.name + ";aerial="  + string(aerial_distance) + ";path=" + string(path_distance); }
				write "PARKING;" + src.name + ";" + dst.name + ";aerial="  + string(aerial_distance) + ";path=" + string(path_distance);
//				path shortest_path_nature <- path_between (ways_graph_nature,src,dst);
//				float path_distance_nature <- src distance_to dst using topology(ways_graph_nature);
//				write "PARKING-nature;" + src.name + ";" + dst.name + ";aerial="  + string(aerial_distance) + ";path=" + string(path_distance_nature) + ";diff=" + (path_distance_nature - path_distance);
			}
		}
		loop src over:bus {
			loop dst over:pois_primary {
				path shortest_path <- path_between (ways_graph,src,dst);
				float aerial_distance <- src distance_to dst;
				float path_distance <- src distance_to dst using topology(ways_graph);
//				if (dst.name = "ID-46: Aussichtspunkt Brocken") { write "BUS: " + src.name + " --> " + dst.name + ": aerial="  + string(aerial_distance) + " ; path=" + string(path_distance); }
				write "BUS: " + src.name + " --> " + dst.name + ": aerial="  + string(aerial_distance) + " ; path=" + string(path_distance);
//				path shortest_path_nature <- path_between (ways_graph_nature,src,dst);
//				float path_distance_nature <- src distance_to dst using topology(ways_graph_nature);
//				write "BUS-nature;" + src.name + ";" + dst.name + ";aerial="  + string(aerial_distance) + ";path=" + string(path_distance_nature) + ";diff=" + (path_distance_nature - path_distance);
			}
		}
		loop src over:towns {
			loop dst over:pois_primary {
				path shortest_path <- path_between (ways_graph,src,dst);
				float aerial_distance <- src distance_to dst;
				float path_distance <- src distance_to dst using topology(ways_graph);
//				if (dst.name = "ID-46: Aussichtspunkt Brocken") { write "TOWN: " + src.name + " --> " + dst.name + ": aerial="  + string(aerial_distance) + " ; path=" + string(path_distance); }
				write "TOWN: " + src.name + " --> " + dst.name + ": aerial="  + string(aerial_distance) + " ; path=" + string(path_distance);
//				path shortest_path_nature <- path_between (ways_graph_nature,src,dst);
//				float path_distance_nature <- src distance_to dst using topology(ways_graph_nature);
//				write "TOWN-nature;" + src.name + ";" + dst.name + ";aerial="  + string(aerial_distance) + ";path=" + string(path_distance_nature) + ";diff=" + (path_distance_nature - path_distance);
			}
		}
	}

}


experiment BATCH type: gui {

	output {

		// the map
		display name:"M A P" refresh:every(refresh_map_every) type:opengl {
			species heatmap aspect:draw_heatmap refresh:true;
			species ca aspect:draw_ca_Revier refresh:true;
			species ca aspect:draw_ca_Bereich refresh:true;
			species nlp aspect:draw_nlp refresh:true;
			species street aspect:draw_street refresh:true;
			species railway aspect:draw_railway refresh:true;
			species parking aspect:draw_parking refresh:true;
			species bus aspect:draw_bus refresh:true;
			species towns aspect:draw_towns refresh:true;
			species train aspect:draw_train refresh:true;
			species pois aspect:draw_pois refresh:true;
			species ways aspect:draw_ways refresh:true;
			species cp aspect:draw_cp refresh:true;
			species tc aspect:draw_tc refresh:true;
		}

		// standard monitors
		monitor name:"STANDARD MONITORS" value:'' color:#black;
		monitor name:"Execution time [s]" value:int((machine_time - t0)/1000) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"Simulation date (calculated)" value:date_calculated color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"Years infos (CSV)" value:years_infos_infostring color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Cycle of this day" value:mod(cycle,date_cycles_per_simulation_day) color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"startcycle (min,mean,max)" value:string(min(list_tc_startcycle))+" / "+string(mean(list_tc_startcycle) with_precision 2)+" / "+string(max(list_tc_startcycle)) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Execution time per tc [s]" value:int((machine_time - t0)/1000/tc_total*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Modeling reduction factor" value:int(10000*modeling_reduction_factor)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Identification" value:identification color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);

		monitor name:"BUGFIXMODE" value:BUGFIXMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"FIXEDQUANTITIES" value:FIXEDQUANTITIES color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"EQUALATTRACTIONSMODE" value:EQUALATTRACTIONSMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"EQUALWEIGHTS" value:EQUALWEIGHTS color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"DRYRUNMODE" value:DRYRUNMODE color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVATEWINTER" value:ACTIVATEWINTER color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVATESUMMER" value:ACTIVATESUMMER color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"ACTIVITYWINTERDAYS" value:ACTIVITYWINTERDAYS color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"numberofwinterdays" value:numberofwinterdays color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Set season_type" value:set_season_type color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Possible_winter" value:possible_winter color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Remaining_winter_days" value:remaining_winter_days color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"total winter days" value:int(total_winter_days) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);
		monitor name:"Shortest path algorithm" value:shortest_path_algorithm color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day);

		// calibration monitors (1)
		monitor name:"CALIBRARTION MONITORS (NO reduction)" value:'' color:#black;
		monitor name:"12   avg. mb per tc" value:int(mb_total/tc_total*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     factor tc bus" value:int(10000*total_tc_bus/total_tc_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"07   factor mb bus" value:int(10000*total_tc_mb_bus/total_tc_mb_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     factor tc town" value:int(10000*total_tc_town/total_tc_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"08   factor mb town" value:int(10000*total_tc_mb_town/total_tc_mb_parking)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"     mb total" value:int(mb_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"01      NLP total" value:int(mb_total_nlp*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        mb OUTSIDE total" value:int(mb_total_outside*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"20   Brocken mb count cp1" value:int(cp[20].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Brocken mb count cp2" value:int(cp[20].sum_tc_members_heading_dir2*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Brocken mb count ca" value:int(ca[0].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"03      Brocken mb train" value:int((total_tc_mb_train_train+total_tc_mb_train_valley)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Brocken mb hiking cp1" value:int((cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Brocken mb hiking ca" value:int((ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"06      Factor Brocken mb t/h cp1" value:int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(cp[20].sum_tc_members_heading_dir1-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Brocken mb t/h ca" value:int(10000*((total_tc_mb_train_train+total_tc_mb_train_valley)/(ca[0].count_tc_members_hiked_area_once-(total_tc_mb_train_train+total_tc_mb_train_valley))))/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"27      Factor Brocken mb of NLP cp1" value:int(int(cp[20].sum_tc_members_heading_dir1)/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
 		monitor name:"        Factor Brocken mb of NLP ca" value:int(ca[0].count_tc_members_hiked_area_once/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"21   Torfhaus mb hiked cp1+cp2" value:int(2*(0.5*cp[24].sum_tc_members_heading_dir1+0.5*cp[26].sum_tc_members_heading_dir1)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Torfhaus mb hiked ca" value:int(ca[12].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"28      Factor Torfhaus mb of NLP cp1+cp2" value:int(2*(0.5*cp[24].sum_tc_members_heading_dir1+0.5*cp[26].sum_tc_members_heading_dir1)/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Torfhaus mb of NLP ca" value:int(ca[12].count_tc_members_hiked_area_once/(countcomplete[0].count_tc_members_hiked_countcomplete)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"23   Rabenklippe mb hiked cp12" value:int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Rabenkl./Luchs. mb hiked ca" value:int(ca[3].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"30      Factor Rabenklippe mb of NLP cp12" value:int((cp[8].sum_tc_members_heading_dir1+cp[8].sum_tc_members_heading_dir2)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Rabenklippe mb of NLP ca" value:int(ca[3].count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"24   Scharfenstein mb hiked cp1" value:int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"     Scharfenstein mb hiked ca" value:int(ca[2].count_tc_members_hiked_area_once*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"31      Factor Scharfenstein mb of NLP cp1" value:int((cp[12].sum_tc_members_heading_dir1+cp[14].sum_tc_members_heading_dir1+cp[16].sum_tc_members_heading_dir1+cp[18].sum_tc_members_heading_dir1)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Scharfenstein mb of NLP ca" value:int(ca[2].count_tc_members_hiked_area_once/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"22   Drei-Annen-Hohne mb hiked cp1" value:int(cp[22].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"29      Factor Drei-Annen-Hohne mb of NLP cp1" value:int(cp[22].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"25   Zantierplatz mb hiked cp1" value:int(cp[10].sum_tc_members_heading_dir1*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"32      Factor Zantierplatz mb of NLP cp1" value:int(cp[10].sum_tc_members_heading_dir1/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"26   Bwpf. mb POI" value:int(pois[79].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Bwpf. mb" value:int(pois[79].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"40   Luchsg. mb POI" value:int(pois[65].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Luchsg. mb" value:int(pois[65].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"41   Brockengar. mb POI" value:int(pois[66].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor Brockengar. mb" value:int(pois[66].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"42   NLP Brocken mb POI" value:int(pois[63].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Brocken mb" value:int(pois[63].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"43   NLP Torfhaus mb POI" value:int(pois[58].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Torfhaus mb" value:int(pois[58].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"44   NLP Hohnehof mb POI" value:int(pois[64].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Hohnehof mb" value:int(pois[64].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"45   NLP Ilsetal mb POI" value:int(pois[60].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Ilsetal mb" value:int(pois[60].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"46   NLP Schierke mb POI" value:int(pois[62].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Schierke mb" value:int(pois[62].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"47   NLP B.Hbg. mb POI" value:int(pois[56].tc_members_at_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP B.Hbg. mb" value:int(pois[56].tc_members_at_target/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"48   NLP Schst. mb POI" value:int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"        Factor NLP Schst. mb" value:int((pois[61].tc_members_at_target+pois[76].tc_members_at_target)/countcomplete[0].count_tc_members_hiked_countcomplete*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"60   CP1%(ZG) (Goetheweg)" value:int(cp[0].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"61   CP2%(ZG) (Str. mitte)" value:int(cp[1].sum_tc_members_at_cp/(cp[0].sum_tc_members_at_cp+cp[1].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"62   CP3%(ZG) (Hirtenstieg)" value:int(cp[2].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"63   CP4%(ZG) (Str. oben)" value:int(cp[3].sum_tc_members_at_cp/(cp[3].sum_tc_members_at_cp+cp[2].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"64   CP15%(ZG) (Eckerloch)" value:int(cp[28].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"65   CP16%(ZG) (Str. unten)" value:int(cp[30].sum_tc_members_at_cp/(cp[28].sum_tc_members_at_cp+cp[30].sum_tc_members_at_cp)*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		monitor name:"80   Bad Harzburg (Brocken) %" value:int(count_brocken_members_percent_BADHARZBURG*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"81   Torfhaus (Brocken) %" value:int(count_brocken_members_percent_TORFHAUS*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"82   Oderbrück (Brocken) %" value:int(count_brocken_members_percent_ODERBRUECK*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"83   Braunlage (Brocken) %" value:int(count_brocken_members_percent_BRAUNLAGE*10000)/10000 color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"84   Schierke (Brocken) %" value:int(count_brocken_members_percent_SCHIERKE*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"85   Drei-Annen-Hohne (Brocken) %" value:int(count_brocken_members_percent_DREIANNENHOHNE*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"86   Ilsenburg (Brocken) %" value:int(count_brocken_members_percent_ILSENBURG*10000)/10000color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);

		// (total) monitors
		monitor name:"TOTAL MONITORS (NO reduction)" value:'' color:#black;
		monitor name:"mb (total)" value:int(mb_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) parking-areas" value:int(total_tc_mb_parking*modeling_reduction_factor) color:parking_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bus-stops" value:int(total_tc_mb_bus*modeling_reduction_factor) color:bus_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) towns" value:int(total_tc_mb_town*modeling_reduction_factor) color:town_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bytrain_train" value:int(total_tc_mb_train_train*modeling_reduction_factor) color:train_train_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) bytrain_valley" value:int(total_tc_mb_train_valley*modeling_reduction_factor) color:train_valley_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) nospace" value:int(total_tc_mb_nospace*modeling_reduction_factor) color:tc_color_nospace refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) notarget]" value:int(total_tc_mb_notarget*modeling_reduction_factor) color:tc_color_notarget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) late]" value:int(total_tc_mb_late*modeling_reduction_factor) color:tc_color_late refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [mb (total) distancebudget]" value:int(total_tc_mb_distancebudget*modeling_reduction_factor) color:tc_color_distancebudget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) target" value:int(total_tc_mb_desttype_target*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) nature" value:int(total_tc_mb_desttype_nature*modeling_reduction_factor)color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  mb (total) hwn" value:int(total_tc_mb_desttype_hwn*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"tc (total)" value:int(tc_total_last*modeling_reduction_factor) color:rgb(235,235,235,255) refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) parking-areas" value:int(total_tc_parking*modeling_reduction_factor) color:parking_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bus-stops" value:int(total_tc_bus*modeling_reduction_factor) color:bus_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) towns" value:int(total_tc_town*modeling_reduction_factor) color:town_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bytrain_train" value:int(total_tc_train_train*modeling_reduction_factor) color:train_train_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) bytrain_valley" value:int(total_tc_train_valley*modeling_reduction_factor) color:train_valley_color refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"  tc (total) nospace" value:int(total_tc_nospace*modeling_reduction_factor) color:tc_color_nospace refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) notarget]" value:int(total_tc_notarget*modeling_reduction_factor) color:tc_color_notarget refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) late]" value:int(total_tc_late*modeling_reduction_factor) color:tc_color_late refresh:every(date_cycles_per_simulation_day-1);
		monitor name:"    [tc (total) distancebudget]" value:int(total_tc_distancebudget*modeling_reduction_factor) color:tc_color_distancebudget refresh:every(date_cycles_per_simulation_day-1);

		// model operating values
		monitor name:"MODEL OPERATING VALUES (WITH reduction)" value:'' color:#black;
		monitor name:"add poi added" value:total_additional_poi_added color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"    add restaurant added" value:total_additional_restaurant_added color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"more than 2 cp" value:total_morethan2cp color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
		monitor name:"nil path" value:total_nilpath color:rgb(235,235,235,255) refresh:every(refresh_monitor_every);
	}
}


// ================================================================================================================================================================================================================
// ================================================================================================================================================================================================================
// ================================================================================================================================================================================================================