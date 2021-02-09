model CSVfileloading

global {

	file year_csv_file <- csv_file("../includes/NLP_Harz/NLP_Harz_year1.csv",";");
	list<string> year_infos_list <- ['day','date','weekday','season','holiday','schoolholiday'];
	matrix year_infos <- matrix(year_csv_file);

	init {
		// convert the years_info-file into a matrix (and set all values)
		loop day from: 0 to: year_infos.rows -1{
			write year_infos_list[0] + "=" + year_infos[0,day] + ", " + year_infos_list[1] + "=" +  year_infos[1,day] + ", " + year_infos_list[2] + "=" + year_infos[2,day] + ", " + year_infos_list[3] + "=" + year_infos[3,day] + ", " + year_infos_list[4] + "=" + year_infos[4,day] + ", " + year_infos_list[5] + "=" + year_infos[5,day];
		}		
	}

}

experiment main type: gui;
