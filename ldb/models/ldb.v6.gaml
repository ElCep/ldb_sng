/***
* Name: ldbv3
* Author: jpmuller
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ldbv3

global {
  // GLOBAL VARIABLES
  // date management
  list<int>   nbDays <- [31,31,30,31,30,31,31,28,31,30,31,30];
  
  // simulation control
  string parameter_name <- "../includes/parameters1.v6.json";
  bool   trace          <- false;  // whether to tace the details of each herd
  string save_name      <- "../results/simulation.csv";
  bool   save           <- false;  // whether to save the resulting data
//  string parameter_name;
//  bool   trace;  // whether to tace the details of each herd
//  string save_name;
//  bool   save;  // whether to save the resulting data

  // the parameters loaded from the parameter file
  map<string, map<string,unknown>> parameters;
  
  // constants for time
  int                 day_per_month; // nb of days per month
  list<string>        months;        // list of month names
  map<string,map<string,float>> seasons;       // list of year qualities (good, bad, etc.)
  list<string>		  sequence;      // list of years to run through
  
  // constants for environment
  // - these ones must be defined here (cannot be externally parameterized)
  file bounds        <- file('../includes/deli.shp'); // the bounds of the space to take into account
  geometry shape     <- geometry(bounds).envelope;    // the bounds of the whole system
  float patch_length <- 500.0;                        // the patch size in m
  // - biomass along the year
  list<list<float>> biomass_percentages; // for each month, the total availability of biomass as percentage of the pic
                                         // and the percentage really usable
  // - carbon impact parameters
  float pasture_ci;      // of pasture production (kgCO2/kg)
  float crop_residue_ci; // of crop residue production (kgCO2/kg)
  float complement_ci;   // of complement production (kgCO2/kg)
  float moto_ci;         // of motorcycle (kgCO2/km)
  float car_ci;          // of car (kgCO2/km)
  // - computed constants
  float patch_surface;   // the surface of a patch (ha)
  float grass_surface;   // the surface of the grassland (ha)

  // constants for milkery
  // - general parameters
  point milkery_patch;                // the point where the milkery is
  int cspNumber          <- 17;       // the number of CSP (Centre de Service Pastoral)
  int collected_price    <- 300;      // price of collected milk (CFA/l)
  int delivered_price    <- 340;      // price of milk delivered to the milkery (CFA/l)
  // - minifarm descriptions
  int nb_minifarms       <- 30;       // the number of minifarms
  int min_mf_herd_size   <- 6;        // the minimum herd size for minifarms
  int max_mf_herd_size   <- 8;        // the maximum herd size for minifarms
  float min_mf_draught_milk <- 5.0;   // the minimum draught milk for minifarms
  float max_mf_draught_milk <- 10.0;  // the maximum draught milk for minifarms
  float mf_veal_need <- 0.5;          // the quantity for the veal (l)
  float mf_complementRainSeason;      // the complement quantity used by minifarms in rain season
  float mf_complementDrySeason;       // the complement quantity used by minifarms in dry season
  
  // constants for herds
  // - general parameters
  float herd_density;
  int percentage_small;
  int percentage_medium;
  int percentage_large;
  float collect_radius;
  float water_radius;
  float residue_radius;
  float road_radius;
  float crop_residue_stock;
  float complementRainSeason;        // the complement quantity used by traditional farms in rain season
  float complementDrySeason;         // the complement quantity used by traditional farms in dry season
  // - herd structure
  float average_small_herd_size;     // average size of a small herd
  float small_herd_sd;               // small herd size standard deviation
  int min_small_herd_size;
  int max_small_herd_size;
  float average_medium_herd_size;    // average size of a medium herd
  float medium_herd_sd;              // medium herd size standard deviation
  int min_medium_herd_size;
  int max_medium_herd_size;
  float average_large_herd_size;     // average size of a large herd
  float large_herd_sd;               // large herd size standard deviation
  int min_large_herd_size;
  int max_large_herd_size;
  int small_consumption;  // small herd milk autoconsumption
  int medium_consumption; // medium herd milk autoconsumption
  int large_consumption;  // large herd milk autoconsumption
  int small_probability;  // small herd transhumance probability
  int medium_probability; // small herd transhumance probability
  int large_probability;  // small herd transhumance probability
  // - zootechnical parameters
  int   cow_ingestion_ratio ;
  float maximum_consumption_zebu;    // maximum consumption per day (kg)
  float maximum_consumption_metisse; // maximum consumption per day (kg)
  int   complement_limit;            // maximum of complement per day (kg)
  int   starving_limit;              // minimum necessary per month
  float upkeep_ufl;                  // UFL for animal upkeep per day
  list<int>    milking_percentages;  // percentage of milking cows within a herd by month
  list<float>  pbiomass2ufl;         // converts 1 kg of pasture biomass into corresponding UFL
  float        rbiomass2ufl;         // converts 1 kg of residue biomass into corresponding UFL
  float        cbiomass2ufl;         // converts 1 kg of complement into corresponding UFL
  float        ufl2liter;            // liter of milk produced by 1 ufl
  float        draught2produced;     // milk produced from draught milk (accounting veal need) for zebu
  list<float>  methane_coefficients; // methane emission coefficients for consumed biomass per month
  
  // economic constants
  list<float>  market_prices;            // price of milk on the market depending on the month
  int          crop_residue_price <- 50; // price of crop residue (CFA/kg)
  int          complement_price;         // price of complement   (CFA/kg)

  // variables changing throughout the simulation
  float  market_milk;                // milk sold on market
  string season;                     // current season
  string season_1 ;                  // previous season (if the previous season was bad, there is half less milking cows)
  float  current_biomass;            // current biomass potential per ha for this month
  
  // various counters for statistics
  int nb_herd_stock;				 // the number of herds making stocks 
  
  // files containing shapes for drawing
  file ldbShape  <- file('../images/ldb.png');    // Laiterie du Berger
  file cpShape   <- file('../images/PC.png');     // collect point
  file cowShape  <- file('../images/vache2.png'); // herd
  file tcowShape <- file('../images/vache3.png'); // herd in transhumance
  file mfShape   <- file('../images/vache.png');  // minifarm
  
  // some optimization
  list<patch> waterPatches     <- [];  // the list of patches where there is surface water
  list<patch> cropPatches      <- [];  // the list of patches where there is crop residue available;
  list<patch> roadPatches      <- [];  // the list of patches where there is a road or track;
  list<patch> pastoralPatches  <- [];  // the list of patches where there is pasture;
  
  // indicators
  float biomass4milk;
  float milk4minifarm;
  float milk4collected;
  float milk4traditional;
  float milk2autoconsumption;
  float milk2milkery;
  float milk2market;
  float producedMilk;
  float minifarmIncome;
  float minifarmExpense;
  float collectedIncome;
  float collectedExpense;
  float traditionalIncome;
  float traditionalExpense;
  float producedCI;
  float collectedCI;
  float biomassHead;
  float biomassHa;
  float cowDensity;
  float pastoral4minifarm;
  float nmPastoral4collected;
  float pastoral4collected;
  float nmPastoral4others;
  float pastoral4others;
  float residue4minifarm;
  float residue4collected;
  float residue4others;
  float complement4minifarm;
  float complement4collected;
  float complement4others;
  int milkingNb;
  int traditionalNb;
  int collectedNb;
  int minifarmNb;
  int traditionalMilkingNb;
  int collectedMilkingNb;
  int minifarmMilkingNb;
  int cowNb;                     // the total number of cows (depends on transhumance)
  
	// initialization
	init {
	  // real variables
	  market_milk <-   0.0;     // initial marketed milk quantity
  	  producedCI  <-   0.0;     // the total carbon impact of produced milch
  	  collectedCI <-   0.0;     // the total carbon impact of collected milch
  	  // load parameters file
  	  file parameterFile <- json_file(parameter_name); 
  	  parameters <- parameterFile.contents;
  	  starting_date <- date([2020,7,1,0,0,0]);
	  // initialization
	  do init_climate();        // sets the season and previous season
	  do init_env();
	  do init_milkery();
	  do init_herds();
	  do load_economic_parameters();
	  do compute_indicators(true);
  	  write 'Initialization completed.';
	}

	// loading parameters 	
	action load_time_parameters {
  		write 'Time parameters';
  		map<string, unknown> time_parameters <- parameters["temps"];
  		day_per_month <- int(time_parameters["joursParMois"]);
  		write '  days per month: '+day_per_month;
	  	months        <- time_parameters["mois"];
  		write '  months: '+months;
	  	seasons       <- time_parameters["saisons"];
  		write '  climates: ';
  		loop sname over: seasons.keys {
   			write '    climate ' + sname + ' max biomass: ' + seasons[sname]["biomasse"];	
  		}
  		sequence      <- time_parameters["sequence"];
  		write '  climate sequence: '+sequence;
	}
	
	action load_env_parameters {
   		write 'Environment parameters';
  		// load parameters
  		map<string, unknown> env_parameters <- parameters["environnement"];
  		//
	  	patch_surface <- patch_length * patch_length / 10000 ;      // ha per patch
  		write '  patch surface(ha): '+patch_surface;
		// ENVIRONNEMENT FROM SHAPEFILES
		// pluvial crop areas
		create PluvialCropShape from: file(env_parameters["culturePluviale"]) {
			height <- 10 + rnd(90);
		}
		// zone irrigue (culture de riz)
		create IrrigatedCropShape from: file(env_parameters["cultureIrriguee"]) {
			height <- 10 + rnd(90);
		}
		// Agriculture intensive
		create IntensiveCropShape from: file(env_parameters["cultureIntensive"]) {
			height <- 10 + rnd(90);
		}
		// the main road
		create RoadShape from: file(env_parameters["routes"]);
		// the tracks
		create TrackShape from: file(env_parameters["pistes"]);
		//mareCadre
//		create PondShape from: ponds;
		// the hydrological system
		create SurfaceWaterShape from: file(env_parameters["eauDeSurface"]);
		// les forages
		create WellShape from: file(env_parameters["puits"]);

		// biomass settings
		biomass_percentages <- env_parameters["pourcentageBiomasse"];
		current_biomass     <- compute_biomass(0);
  		write '  initial biomass: '+current_biomass;
		// carbon impact settings
		pasture_ci      <- float(env_parameters["ICpastoral"]);
		crop_residue_ci <- float(env_parameters["ICresidus"]);
		complement_ci   <- float(env_parameters["ICcomplement"]);
		moto_ci         <- float(env_parameters["ICmoto"]);
		car_ci          <- float(env_parameters["ICvoiture"]);
  		write '  carbon impact: '+pasture_ci+', '+crop_residue_ci+', '+complement_ci+', '+moto_ci+', '+car_ci;		
	}

	action load_milkery_parameters {
		write 'Milkery parameters';
		// the milkery itself
  		map<string, unknown> milkery_parameters <- parameters["laiterie"];
		create Milkery from: file(milkery_parameters["position"]) {
			milkery_patch <- self.location;
		}
  		write '  milkery created at: '+milkery_patch;
//  		collected_price    <- int(milkery_parameters["prixCollecte"]);
//  		delivered_price    <- int(milkery_parameters["prixLivre"]);
  		write '  milch prices: '+collected_price+', '+delivered_price;
//  	cspNumber          <- int(milkery_parameters["nombreCSP"]);
  		write '  CSP number: '+cspNumber;
  		
		// creates the collect points
		create CollectPoint from: file(milkery_parameters["pointsDeCollecte"]);
  		write '  collect points created: ' + length(CollectPoint);
  		
  		// initializes the mini-farm
  		map<string, unknown> minifarms <- milkery_parameters["minifermes"];
//    	nb_minifarms     <- int(minifarms["nombre"]);       	   // the number of minifarms
  		min_mf_herd_size <- int(minifarms["tailleMinimum"]);       // the minimum herd size for minifarms
  		max_mf_herd_size <- int(minifarms["tailleMaximum"]);       // the maximum herd size for minifarms
  		min_mf_draught_milk <- float(minifarms["minLaitTrait"]); // the minimum draught milk for minifarms
  		max_mf_draught_milk <- float(minifarms["maxLaitTrait"]); // the maximum draught milk for minifarms
  		mf_veal_need <- float(minifarms["laitVeau"]);            // the quantity of milk to veal (l)
  		mf_complementRainSeason <- float(minifarms["complementHivernage"]); // complement quantity in rain season for minifarms
  		mf_complementDrySeason  <- float(minifarms["complementEstive"]);    // complement quantity in dry season for minifarms
  		write '  number of minifarms: ' + nb_minifarms;
  		write '  minifarm herd size: ' + min_mf_herd_size + '...'+max_mf_herd_size;
  		write '  minifarm milk production: ' + min_mf_draught_milk + '...'+max_mf_draught_milk;	
  		write '  minifarm veal need: ' + mf_veal_need;	
  		write '  minifarm complement use (rain/dry): ' + mf_complementRainSeason + ', '+mf_complementDrySeason;	
	}
	
	action load_herd_parameters {
  	  write 'Herd parameters';
  	  map<string,unknown> herd_parameters <- parameters["troupeaux"];
  	  herd_density        <- float(herd_parameters["densite"]);
  	  write '  herd density: ' + herd_density;
  	  milking_percentages <- herd_parameters["pourcentageAllaitantes"];
  	  write '  milking cow proportions: ' + milking_percentages;
  	  collect_radius      <- float(herd_parameters["accesCollecte"]);
  	  water_radius        <- float(herd_parameters["accesEau"]);
  	  residue_radius      <- float(herd_parameters["accesResidus"]);
  	  road_radius         <- float(herd_parameters["accesRoute"]);
  	  write '  distances to ressources: ' + collect_radius + ', ' + water_radius + ', ' + residue_radius;
  	  crop_residue_stock  <- float(herd_parameters["stockResidus"]);
  	  write '  initial residue stock: ' + crop_residue_stock;
  	  complementRainSeason <- float(herd_parameters["complementHivernage"]); // complement quantity in rain season
  	  complementDrySeason  <- float(herd_parameters["complementEstive"]);    // complement quantity in dry season
  	  write '  complement use (rain/dry): ' + complementRainSeason + ', ' + complementDrySeason;	
  	  // small herds
  	  write '  small herd parameters:';
   	  map<string,unknown> small_parameters <- herd_parameters["petit"];
   	  percentage_small        <- int(small_parameters["pourcentage"]);
  	  write '    proportion: ' + percentage_small;
	  average_small_herd_size <- float(small_parameters["tailleMoyenne"]); // average size of a small herd
	  small_herd_sd           <- float(small_parameters["ecartType"]);     // small herd size standard deviation
      min_small_herd_size <- int(small_parameters["tailleMin"]);
	  max_small_herd_size <- int(small_parameters["tailleMax"]);
  	  write '    size: ' + average_small_herd_size + ', ' + small_herd_sd + ' (' + min_small_herd_size + ',' + max_small_herd_size + ')';
	  small_probability       <- int(small_parameters["probabiliteTranshumance"]);
  	  write '    transhumance probability: ' + small_probability;
  	  small_consumption       <- int(small_parameters["autoconsommation"]);
  	  write '    autoconsumption: ' + small_consumption;
  	  // medium herds
  	  write '  medium herd parameters:';
   	  map<string,unknown> medium_parameters <- herd_parameters["moyen"];
   	  percentage_medium        <- int(medium_parameters["pourcentage"]);
  	  write '    proportion: ' + percentage_medium;
	  average_medium_herd_size <- float(medium_parameters["tailleMoyenne"]); // average size of a medium herd
	  medium_herd_sd           <- float(medium_parameters["ecartType"]);     // medium herd size standard deviation
      min_medium_herd_size <- int(medium_parameters["tailleMin"]);
	  max_medium_herd_size <- int(medium_parameters["tailleMax"]);
  	  write '    size: ' + average_medium_herd_size + ', ' + medium_herd_sd + ' (' + min_medium_herd_size + ',' + max_medium_herd_size + ')';
	  medium_probability       <- int(medium_parameters["probabiliteTranshumance"]);
  	  write '    transhumance probability: ' + medium_probability;
  	  medium_consumption       <- int(medium_parameters["autoconsommation"]);
  	  write '    autoconsumption: ' + medium_consumption;
  	  write '  large herd parameters:';
  	  // large herds
   	  map<string,unknown> large_parameters <- herd_parameters["grand"];
   	  percentage_large        <- int(large_parameters["pourcentage"]);
  	  write '    proportion: ' + percentage_large;
 	  average_large_herd_size <- float(large_parameters["tailleMoyenne"]); // average size of a large herd
	  large_herd_sd           <- float(large_parameters["ecartType"]);     // large herd size standard deviation
      min_large_herd_size <- int(large_parameters["tailleMin"]);
	  max_large_herd_size <- int(large_parameters["tailleMax"]);
  	  write '    size: ' + average_large_herd_size + ', ' + large_herd_sd + ' (' + min_large_herd_size + ',' + max_large_herd_size + ')';
	  large_probability       <- int(large_parameters["probabiliteTranshumance"]);
   	  write '    transhumance probability: ' + large_probability;
  	  large_consumption       <- int(large_parameters["autoconsommation"]);
  	  write '    autoconsumption: ' + large_consumption;
  	  
	  // herd type check
	  if (percentage_small + percentage_medium + percentage_large != 100) {
	    warn "The percentage of small, medium and large herds do not sum to 100%";
	    do pause();
	  }
		
	  // zootechnical parameters
      write '  zootechnical parameters';
   	  map<string,unknown> zoo_parameters <- herd_parameters["zootechnie"];
      cow_ingestion_ratio  <- int(zoo_parameters["tauxIngestion"]);
      write '    ingestion rate: ' + cow_ingestion_ratio;
      maximum_consumption_zebu     <- float(zoo_parameters["consommationMaxZebu"]);    // maximum consumption per day (kg)
      maximum_consumption_metisse  <- float(zoo_parameters["consommationMaxMetisse"]); // maximum consumption per day (kg)
      starving_limit       <- int(zoo_parameters["niveauFamine"]);      // minimum necessary per month
      write '    physiological parameters (min,max): ' + starving_limit + ", " + maximum_consumption_zebu*day_per_month
      		+ ", " + maximum_consumption_metisse*day_per_month ;
      complement_limit     <- int(zoo_parameters["niveauComplement"]);  // maximum of complement per day (kg)
      write '    complement limit: ' + starving_limit;
      write '    milk production';
	  // conversion of 1 kg of pasture biomass into corresponding UFL depending on the month
	  pbiomass2ufl         <- zoo_parameters["pastoralVersUFL"];
      write '      pastoral biomass to UFL: ' + pbiomass2ufl;
	  // conversion of 1 kg of residue biomass into corresponding UFL
	  rbiomass2ufl         <- float(zoo_parameters["residuVersUFL"]);
      write '      residue biomass to UFL: ' + rbiomass2ufl;
	  // conversion of 1 kg of complement into corresponding UFL
	  cbiomass2ufl         <- float(zoo_parameters["complementVersUFL"]);
      write '      complement biomass to UFL: ' + cbiomass2ufl;
	  // UFL for animal upkeep per day
      upkeep_ufl           <- float(zoo_parameters["maintenanceUFL"]);  
      write '      upkeep UFL: ' + upkeep_ufl;
	  // converion of 1 UFL to milk liters
	  ufl2liter            <- float(zoo_parameters["UFLVersLitre"]);
      write '      UFL for 1 liter: ' + ufl2liter;
	  // conversion from draught milk to produced (human used) milk
	  draught2produced     <- float(zoo_parameters["tireVersProduit"]);
      write '      draught liter to produced liter: ' + draught2produced;
	  // methane emission depending on the eated biomass
	  methane_coefficients <- zoo_parameters["coefficientsMethane"];
      write '      methane emission: ' + methane_coefficients;
	  
	}
	
	action load_economic_parameters {
  	  write 'Economic parameters';
  	  map<string,unknown> eco_parameters <- parameters["economie"];		
	  // evolution of milk market price
	  market_prices <-  eco_parameters["prixLait"];
  	  write '  milk prices: ' + market_prices;
//  	  crop_residue_price <- int(eco_parameters["prixResidus"]);
  	  write '  crop residue price: ' + crop_residue_price;
  	  complement_price <- int(eco_parameters["prixComplement"]);
  	  write '  complement price: ' + complement_price;
	}
	
	// detailed initialization
	action init_climate { // sets the season and previous season
   		// load parameters
   		do load_time_parameters;
   		
  		write 'Init climate';
  		// init season
  		if (empty(sequence)) {
//	  		season_1 <- one_of(seasons.keys);
	  		season   <- one_of(seasons.keys);
	  	} else {
//	  		season_1 <- sequence[0];
	  		season   <- sequence[0];
	  	}
//	  	write '  Previous season: '+season_1+', current season: '+season;
	  	write '  Current climate: '+season;
  	}

	action init_env { // initialize the environment
  		// load parameters
  		do load_env_parameters;
  		
  		write 'Init environment';
		// init counter
		int grass_cnt <- 0;
		// set all to pastoral surface
		ask patch {  
			cover <- "paturage1";
			color <- #yellow;
			grass_cnt <- grass_cnt + 1;
			biomass   <- current_biomass * patch_surface;
			add self to: pastoralPatches;
		}
		// remove everythig else
		ask patch overlapping union([geometry(IrrigatedCropShape),geometry(IntensiveCropShape)]) {
			cover <- "champs1";
			color <- #darkgreen;
			grass_cnt <- grass_cnt - 1;
			biomass   <- 0.0;
			add self to: cropPatches;
		}
		ask patch overlapping geometry(PluvialCropShape) {
			cover <- "champs2";
			color <- #green;
			grass_cnt <- grass_cnt - 1;
			biomass   <- 0.0;
			add self to: cropPatches;
		}
		ask patch overlapping geometry(SurfaceWaterShape) {
			cover <- "eau";
			color <- #darkblue;
			grass_cnt <- grass_cnt - 1;
			biomass   <- 0.0;
			add self to: waterPatches;
		}
		ask patch overlapping geometry(TrackShape) {
			cover <- "piste";
			color <- #darkgrey;
			grass_cnt <- grass_cnt - 1;
			biomass   <- 0.0;
			add self to: roadPatches;
		}
		ask patch overlapping geometry(RoadShape) {
			cover <- "route";
			color <- #black;
			grass_cnt <- grass_cnt - 1;
			biomass   <- 0.0;
			add self to: roadPatches;
		}
		grass_surface <- grass_cnt * patch_surface;
 		write '  Number of patches: '+length(patch);		
 		write '    with '+length(pastoralPatches)+' pastoral patches';		
 		write '    with '+length(cropPatches)    +' crop patches';		
 		write '    with '+length(waterPatches)   +' water patches';		
 		write '    with '+length(roadPatches)    +' road patches';		
  		write '  Grass surface (ha): '+grass_surface;		
	}

	
	action init_milkery {
  		// load parameters
  		do load_milkery_parameters;
  		
  		write 'Init milkery';
		// inits counter and ordered list of collect points from milkery
		int csp_count <- cspNumber;
		list<CollectPoint> cps <-  CollectPoint sort_by (each.location distance_to milkery_patch);
		loop while: (!empty(cps) and csp_count > 0) {  // for each one
			ask    cps[0] { csp <- true; }
			remove cps[0] from: cps;
			csp_count <- csp_count - 1;
		}	
	}
	
	action init_herds { //create the herds depending on the density and size distribution
  	  // load parameters
  	  do load_herd_parameters;
  	  
  	  write 'Init herds';
	  // nb of herds to create
	  int nb_herds <- int(floor(grass_surface / 100 * herd_density));
	  // the possible patches to put the herds on
	  list<patch> lst <- patch where (each.cover = "paturage1" or each.cover = "paturage2");
	  // create the herds uniformly on the grassland
  	  write '  Creating ' + nb_herds + ' herds';
  	  int smallNb     <- 0;
  	  int mediumNb    <- 0;
  	  int largeNb     <- 0;
  	  int collectedNb <- 0;	
 	  int cropNb      <- 0;
 	  int roadNb      <- 0;
	  create Herd number: nb_herds {
	    // choose a patch
	    patch p <- one_of(lst);
	    // standard setting
		location     <- p.location;
	    transhumance <- false;
	    float alea <- rnd(0.0,100.0);
	    if (alea <= percentage_small) {                             // create small herd
	      htype <- "small";
	      herd_size <- int(ceil(gauss(average_small_herd_size,small_herd_sd)));
	      herd_size <- max([herd_size,min_small_herd_size]);        // cannot be less than the min
	      smallNb <- smallNb + 1;
	    } else if (alea <= percentage_small + percentage_medium) {  // create medium herd
	      htype <- "medium";
	      herd_size <- int(ceil(gauss(average_medium_herd_size,medium_herd_sd)));
	      herd_size <- max([herd_size,min_medium_herd_size]);       // cannot be less than the min
	      mediumNb <- mediumNb + 1;
	    } else {                                                    // create large herd
	      htype <- "large";
	      herd_size <- int(ceil(gauss(average_large_herd_size,large_herd_sd)));
	      herd_size <- max([herd_size,min_large_herd_size]);        // cannot be less than the min
	      largeNb <- largeNb + 1;
	    }
	    // link to the closest collect point within a radius
	    list<CollectPoint> alst <- CollectPoint where ((location distance_to each.location) <= collect_radius#km);
	    collectPoint <- one_of(alst);
	    if (collectPoint != nil) {
	    	ask collectPoint { add myself to: herds; }
	    	collectedNb <- collectedNb + 1;
	    }
	    // the milking cow as a portion of the herd
	    do herd_milking_nb(0);
	    // remove the chosen patch
	    remove p from: lst;
	    // caches
	    cropAround <- !empty(cropPatches where (location distance_to each.location <= residue_radius#km));
	    if (cropAround) {cropNb <- cropNb + 1;}
	    roadAround <- !empty(roadPatches where (location distance_to each.location <= road_radius#km));
	    if (roadAround) {roadNb <- roadNb + 1;}
	  }
  	  write '  Herds created: ' + nb_herds;
  	  write '    with ' + smallNb + ' small farms,';
  	  write '    with ' + mediumNb + ' medium farms,';
  	  write '    with ' + largeNb + ' large farms,';
  	  write '    and ' + collectedNb + ' farms linked to collect points,';
   	  write '        ' + cropNb + ' farms close to crop,';
   	  write '        ' + roadNb + ' farms close to road or track.';
  	  
  	  write 'Init minifarms';
	  // converts some herds into mini-farm
	  int cnt <- nb_minifarms;
	  nb_herd_stock <- 0;
	  ask Herd {
	    if (cnt > 0    and 			// still mini farms to create
	        collectPoint != nil and // connected to a collect point
	        cropAround and 			// and not to far from a source of residue
	        // not to far from surface water or wells
	        (!empty(waterPatches where (self.location distance_to each.location <= water_radius#km)) or
	       	 !empty(WellShape where (self.location distance_to each.location <= water_radius#km)))) { 
	      htype      <- "minifarm";
	      herd_size  <- rnd(min_mf_herd_size,max_mf_herd_size);
	      consumed   <- float(small_consumption);                    // milk auto-consumption
	      cnt        <- cnt - 1;
	    }
	  }
	  write "  " + cnt + " mini-farms not allocated over " + nb_minifarms;
	  do compute_cow_nb();
	  write "  " + cowNb + " cows";
	}

	// an action to update the total number of cows in the simulation
	action compute_cow_nb {
	  cowNb <- Herd where (!each.transhumance) sum_of (each.herd_size);
	}
	
	// EQUATIONS
	// computes the available biomass in a patch depending on the month and season
	float compute_biomass(int month) {
	  float abiomass <- float(seasons[season]["biomasse"]);
	  list<float> percentages  <-  biomass_percentages[month]; // [%pic biomass %consumed]
	  abiomass <- abiomass * percentages[0];                   // total available biomass / ha
	  return (abiomass * percentages[1] / 100);
	}

	// DYNAMICS
	int monthNb <- 0;
	int yearNb  <- 0;
	
	// advances time (month and year)
	reflex nextMonth {
		// new monthly cycle of simulation
		write "Year: " + yearNb + ", month: " + months[monthNb];
		// beginning of the year
		if (monthNb = 0) {	   
		    do new_climate;             // generates new season quality
		    nb_herd_stock <- 0;
		    ask Herd {					// all the herds comme back
		      transhumance <- false;
		      do herd_make_stock;       // possibly buy crop residue stock
		    }
			write "  " + nb_herd_stock + " herds made stock.";			
		}
		// advances all dynamics
		do step;
		// prepares next cycle
		monthNb <- (monthNb + 1) mod 12;
		if (monthNb = 0) {
			yearNb <- yearNb + 1;
			// end of the simulation
			if (yearNb = 11) {
				do pause();
			}
		}
	}
	
	// generates new season quality
	action new_climate {
		if (empty(sequence)) {
		  season_1 <- season;
		  season   <- one_of(seasons.keys);
		} else {
		  season_1 <- season;
		  season <- sequence[yearNb mod length(sequence)]		;
		}
		write "  new season: " + season;
	}
	
	// One step simulation
	action step {
	  // set date
	  current_date <- current_date + nbDays[cycle mod 12] #day;
	  write "  Initialize finance";			
	  ask Herd { // reset monthly economic indicators
	  	income  <- 0.0;
	  	expense <- 0.0;
	  }    
	  // reset milk sold on market
	  write "  Initialize marketed milk";			
	  market_milk <- 0.0;
	  // reset monthly collected milk
	  write "  Initialize collected milk";			
	  ask CollectPoint {
	    cmilk <- 0.0;
	  }
	  // current level of biomass per ha and then per patch
	  write "  Distribute biomass";			
	  current_biomass <- compute_biomass(monthNb);
	  ask pastoralPatches {
	    biomass <- current_biomass * patch_surface;
	  }
	  // computes the number of cows taking into account transhumance
	  do compute_cow_nb;
	  write "  " + cowNb + " cows";
	  // monthly herd milk production
	  ask Herd {
	  	// number of milking cows
		do herd_milking_nb(monthNb); 
	    // computes consumption with cost
	    do herd_consume_biomass(monthNb);
	    // computes milk production
	    do herd_produce_milk(monthNb);
	    // computes milk distribution with revenue
	    do herd_distribute_milk(monthNb);
	  }
	  // total carbon balance (including herd impact)
	  do compute_indicators(false);
	}
	
	action compute_indicators(bool rewrite) {
	  int   month <- monthNb+yearNb*12;
	  list<Herd> milking_herds <- Herd where (each.milking_nb > 0 and !each.transhumance);
	  milkingNb          <- milking_herds sum_of (each.milking_nb);
	  int nonMilkingNb   <- cowNb - milkingNb;
	  // milk destination
	  producedMilk         <- milking_herds sum_of (each.milk*each.milking_nb);
	  milk2autoconsumption <- milking_herds sum_of (each.consumed);
	  milk2milkery         <- CollectPoint  sum_of (each.cmilk);
	  milk2market          <- market_milk;
	  // biomass productivity
	  if (producedMilk != 0) {
	  	biomass4milk <- milking_herds sum_of ((each.total_pb_consumed + each.total_crb_consumed + each.total_cb_consumed)) / producedMilk;
	  } else {
	  	biomass4milk <- 0.0;
	  }
	  // mini farms
	  list<Herd> minifarms <- Herd where (each.htype  = "minifarm");
	  list<Herd> milking_minifarms <- minifarms where (each.milking_nb != 0);
	  minifarmNb          <- milking_minifarms sum_of (each.herd_size);
	  minifarmMilkingNb   <- milking_minifarms sum_of (each.milking_nb);
	  milk4minifarm       <- milking_minifarms sum_of (each.milk * each.milking_nb) / minifarmMilkingNb;
	  minifarmIncome      <- milking_minifarms sum_of (each.income)              / max([1,length(milking_minifarms)]);
	  minifarmExpense     <- milking_minifarms sum_of (each.expense)             / max([1,length(milking_minifarms)]);
   	  pastoral4minifarm   <- milking_minifarms sum_of (each.pasture_biomass * each.milking_nb)     / minifarmMilkingNb;
      residue4minifarm    <- milking_minifarms sum_of (each.residue_biomass * each.milking_nb)     / minifarmMilkingNb;
      complement4minifarm <- milking_minifarms sum_of (each.complement_biomass * each.milking_nb)  / minifarmMilkingNb;
	  // collected farms
	  list<Herd> collected <- Herd where (!each.transhumance and (each.htype = "minifarm" or each.collectPoint != nil));
	  list<Herd> milking_collected <- collected where (each.milking_nb != 0);
	  collectedNb          <- collected sum_of (each.herd_size);
	  collectedMilkingNb   <- milking_collected sum_of (each.milking_nb);
	  milk4collected       <- milking_collected sum_of (each.milk * each.milking_nb) / collectedMilkingNb;
	  collectedIncome      <- milking_collected sum_of (each.income)             / max([1,length(milking_collected)]);
	  collectedExpense     <- milking_collected sum_of (each.expense)            / max([1,length(milking_collected)]);
   	  nmPastoral4collected <- collected sum_of (each.nm_pasture_biomass * (each.herd_size - each.milking_nb)) / (collectedNb - collectedMilkingNb);
      pastoral4collected   <- milking_collected sum_of (each.pasture_biomass * each.milking_nb)    / collectedMilkingNb;
      residue4collected    <- milking_collected sum_of (each.residue_biomass * each.milking_nb)    / collectedMilkingNb;
      complement4collected <- milking_collected sum_of (each.complement_biomass * each.milking_nb) / collectedMilkingNb;
	  // traditional farms
	  list<Herd> traditional <- Herd where (!each.transhumance and each.htype  != "minifarm" and each.collectPoint = nil);
	  list<Herd> milking_traditional <- traditional where (each.milking_nb != 0);
	  traditionalNb        <- traditional sum_of (each.herd_size);
	  traditionalMilkingNb <- traditional sum_of (each.milking_nb);
	  milk4traditional     <- milking_traditional sum_of (each.milk * each.milking_nb) / traditionalMilkingNb;
	  traditionalIncome    <- milking_traditional sum_of (each.income)             / max([1,length(milking_traditional)]);
	  traditionalExpense   <- milking_traditional sum_of (each.expense)            / max([1,length(milking_traditional)]);
   	  nmPastoral4others <- traditional sum_of (each.nm_pasture_biomass * (each.herd_size - each.milking_nb)) / (traditionalNb - traditionalMilkingNb);
      pastoral4others      <- milking_traditional sum_of (each.pasture_biomass * each.milking_nb)    / traditionalMilkingNb;
      residue4others       <- milking_traditional sum_of (each.residue_biomass * each.milking_nb)    / traditionalMilkingNb;
      complement4others    <- milking_traditional sum_of (each.complement_biomass * each.milking_nb) / traditionalMilkingNb;
	  // others
	  biomassHead <- pastoralPatches sum_of (each.biomass) / cowNb;
	  biomassHa   <- pastoralPatches sum_of (each.biomass) / grass_surface;
	  cowDensity  <- cowNb / grass_surface;
	  // carbon impact
	  ask Herd {               // for each heard
	  	do herd_carbon_impact(monthNb);
	  }
	  // carbon impact of each herd for milk production
	  float carbon_impact <- Herd where (!each.transhumance and each.milking_nb != 0) sum_of (each.hcarbon_impact);
	  if (producedMilk != 0) {
	  	producedCI <- carbon_impact / producedMilk;
	  } else {
	  	producedCI <- 0.0;
	  }
	  
	  // computes the distance to each collect point in km
	  float milkery_km <- 0.0;
	  float herd_km    <- 0.0;
	  ask CollectPoint {
	    if (cmilk != 0) {
	      // accumulate km from the herds to the collect points
	      herd_km <- herd_km + herds sum_of (myself.location distance_to self.location) / 1000;
	      // accumulate km from the collect points to the milkery
	      milkery_km <- milkery_km + (self.location distance_to milkery_patch);
	    }
	  }
	  float collected_impact <- Herd where (!each.transhumance and each.milking_nb != 0 and each.collectPoint != nil)
	                            sum_of (each.hcarbon_impact);
	  collectedCI <- (collected_impact + herd_km * moto_ci + milkery_km * car_ci) / max([1,milk2milkery]);
	  write "  Carbon impact: " + producedCI + ', ' + collectedCI;			
	  
	  if (save) {
		save [month,biomass4milk,
			  milk4minifarm,milk4collected,milk4traditional,milk2autoconsumption,milk2milkery,milk2market,producedMilk,
			  minifarmIncome,minifarmExpense,collectedIncome,collectedExpense,traditionalIncome,traditionalExpense,
			  producedCI,collectedCI,biomassHead,biomassHa,
			  cowDensity,cowNb,milkingNb,minifarmNb,collectedNb,traditionalNb,
			  pastoral4minifarm,pastoral4collected,pastoral4others,nmPastoral4collected,nmPastoral4others,residue4minifarm,residue4collected,residue4others,complement4minifarm,complement4collected,complement4others
		] to: save_name type:"csv" rewrite: rewrite;	  	
	  }
	}

}

// The herd species
// species Herd parent: graph_node edge_species: edge_agent {
species Herd {
  	// The attributes
  	string htype;              // "minifarm", "small", "medium", or "large"
  	bool transhumance;         // is the herd in transhumance or not
  	int herd_size;             // total number of cows
  	int milking_nb;            // number of milking cows
  	float stock;               // kg of crop residue
  	float stock_month;         // kg of crop residue available per month
  	float milk;                // monthly produced milk per head
  	float consumed;            // auto-consumption
  	float income;              // monthly income
  	float expense;			   // monthly expense
  	float hcarbon_impact;      // carbon impact of milk production
  	float total_pb_consumed;   // total quantity of consumed pastoral biomass
  	float total_crb_consumed;  // total quantity of consumed crop residue biomass
  	float total_cb_consumed;   // total quantity of consumed complement biomass
	float pasture_biomass; 	   // monthly consumed pasture biomass per milking head
	float nm_pasture_biomass;  // monthly consumed pasture biomass per non milking head
	float residue_biomass; 	   // monthly consumed residue biomass per milking head
	float complement_biomass;  // monthly consumed residue biomass per milking head
  	CollectPoint collectPoint; // the collect point it is connected to
  	// some caches to speed up simulation
//  	bool milkeryAround      <- false;
  	bool cropAround;
  	bool roadAround;
//  	bool collectPointaround <- false;
  	
  	// as a graph node
//    bool related_to (graph_node other) {
//    	return collectPoint = other;
//    }

	// DYNAMICS
  	// computes the number of milking cows in a herd depending on the month
	// 0 -> July,...,11 -> June
	action herd_milking_nb(int month) {
	  if (!transhumance) {
		  if (htype = "minifarm") {
		    milking_nb <- herd_size;
		  } else {
		    float nb <- milking_percentages[month] * herd_size / 100;
		    // if the previous season was bad, there is half less milking cows
		    if (season_1 = "mauvaise") {
		      milking_nb <- int(floor(nb / 2));
		    } else {
		      milking_nb <- int(floor(nb));
		    }
		  }
	  } else {
	  	milking_nb <- 0;
	  }
	}

	// possibly buy crop residue stock at the begining of the year
	action herd_make_stock {
	  // if there is possibility of crop residues around the herd
	  if (htype != "minifarm" and cropAround) {
	    stock         <- crop_residue_stock;                   // get the stock
//	    expense       <- expense + stock * crop_residue_price; // pay the price...or maybe free ?
	    stock_month   <- 0.0;                                  // not needed yet: distribution over the remaining year when starving starts
	    nb_herd_stock <- nb_herd_stock + 1;					   // update counter
	  }
	}
	// biomass consumption
	action herd_consume_biomass(int month) {
	  if (not transhumance and milking_nb > 0) {
		  // consumption
		  pasture_biomass    <- 0.0;    // monthly consumed pasture biomass per head per month
		  residue_biomass    <- 0.0; 	// monthly consumed residue biomass per head per month
		  complement_biomass <- 0.0; 	// monthly consumed complement biomass per head per month
		  // available pasture biomass per head per month on the whole territory
		  float available_pbiomass <- current_biomass * grass_surface / cowNb  * (cow_ingestion_ratio  / 100);
	  	  if (htype != "minifarm") {
	  	  	// maximum ingestion possibility per head per month
		    float biomass_to_consume <- maximum_consumption_zebu * day_per_month;
		    // non-milking cow consumption (only pastoral biomass!)per head per month
		    nm_pasture_biomass <- min([available_pbiomass, biomass_to_consume]);
		    // complement strategy for milking cows
		    if (collectPoint != nil and collectPoint.csp) {  // complement available
		      if (is_rainy_season(month)) {
		        	complement_biomass <- complementRainSeason * day_per_month;
		      } else {
		        	complement_biomass <- complementDrySeason * day_per_month;	        	
		      }
			  expense <- expense + complement_biomass * complement_price * milking_nb;           // total complement expense
			  biomass_to_consume <- biomass_to_consume - complement_biomass;
		    }	      
		    // actually consumed pasture biomass per head per month
		    pasture_biomass <- min([available_pbiomass, biomass_to_consume]);
			biomass_to_consume <- biomass_to_consume - pasture_biomass;
		    // crop residue biomass from nearby crops
		    if (biomass_to_consume > 0) {                     // not enough
		       if (stock_month = 0) {                         // not used yet
		          stock_month <- stock / (12 - month);        // distribute on remaining months
		       }
		       residue_biomass <- min([stock_month / milking_nb, biomass_to_consume]); // get the residue quantity per milking cow per month
		       biomass_to_consume <- biomass_to_consume - residue_biomass;
		    }
		    // crop residue biomass from csp
		    if (biomass_to_consume > 0 and collectPoint != nil and collectPoint.csp) { // further crop residue available
			    residue_biomass <- residue_biomass + biomass_to_consume;  // buy all necessary
			    expense         <- expense + biomass_to_consume * crop_residue_price * milking_nb; // total residue expense
		    }
		    // if starving
		    float feed_lack <- starving_limit - pasture_biomass - residue_biomass - complement_biomass;
		    if (feed_lack > 0) {
		      if (herd_transhumance_decision(month)) {               // transhumance decision
		       	// the herd goes out of the system for the next turn
		        transhumance    <- true;
		      } else if (collectPoint != nil and collectPoint.csp) { // complete with concentrate
		        expense            <- expense + feed_lack * complement_price * milking_nb;        // total complement expense
		        complement_biomass <- complement_biomass + feed_lack;
		       }
		    }	  		
		  } else {  // mini-farm
	  	  	  // maximum ingestion possibility kgDM per head per month
		      float max_consumed_biomass <- maximum_consumption_metisse * day_per_month;
	 	      float prod                 <- rnd(min_mf_draught_milk,max_mf_draught_milk);   // milk draught per head per day
		      float ufl                  <- (prod + mf_veal_need) * ufl2liter + upkeep_ufl; // ufl necessary for this production per head per day
		      // complement and pasture strategy
		      if (is_rainy_season(month)) {
		  		// complement use
		      	complement_biomass <- mf_complementRainSeason * day_per_month;          // kgDM per head per month
		      	ufl <- ufl - (mf_complementRainSeason / day_per_month * cbiomass2ufl);  // remaining UFL per head per day
		      	max_consumed_biomass <- max_consumed_biomass - complement_biomass;      // updated ingestion possibility
//		      	write "->" + self+" complement ufl:"+mf_complementRainSeason / cbiomass2ufl* day_per_month;
			    // remaining pasture use
			    pasture_biomass <- min([available_pbiomass,max_consumed_biomass]);      // kgDM per head per month
			    ufl <- ufl - (pasture_biomass / day_per_month * pbiomass2ufl[month]);   // remaining UFL per head per day
			    if (ufl < 0) { // too much consumption
			    	ufl <- 0.0;
			    	pasture_biomass <- pasture_biomass - (abs(ufl) / pbiomass2ufl[month]); // bring back consumed biomass
			    }
		      	max_consumed_biomass <- max_consumed_biomass - pasture_biomass;         // updated ingestion possibility
//		      	write "->" + self+" pasture ufl:"+pasture_biomass / pbiomass2ufl[month];
		      } else {
		      	// only complement
		      	complement_biomass <- mf_complementDrySeason * day_per_month;           // kgDM per head per month      	
		      	ufl <- ufl - (mf_complementDrySeason / day_per_month * cbiomass2ufl);   // UFL per head per day
		      	max_consumed_biomass <- max_consumed_biomass - complement_biomass;      // updated ingestion possibility
//		      	write "->" + self+" complement ufl:"+mf_complementDrySeason / cbiomass2ufl* day_per_month;
		      }
		      expense <- expense + (complement_biomass * milking_nb * complement_price);   // total cost for complement
		      // residue consumption
		      residue_biomass <- min([max_consumed_biomass,(ufl / rbiomass2ufl) * day_per_month]); // monthly residue biomass per head necessary for this production up to ingestion capacity
		      expense <- expense + (residue_biomass * milking_nb * crop_residue_price);    // total cost of crop residue	  		
//		      write "->" + self+" expected production:"+prod+"("+(prod / draught2produced * ufl2liter + upkeep_ufl)*day_per_month+","+complement_biomass+","+residue_biomass+","+pasture_biomass+")";
	  		}
	  }
	  // total consumed biomass
	  total_pb_consumed  <- pasture_biomass * milking_nb;
	  total_crb_consumed <- residue_biomass * milking_nb;
	  total_cb_consumed  <- complement_biomass * milking_nb;
	  // here we have the consumption of the milking cows
	}
	// milk production
	action herd_produce_milk(int month) {
	  // nb of milking cows is known
	  // computes the monthly milk production per head given the ingested quantity
	  // of pastoral biomass (pasture_biomass), the quantity of crop residue biomass (residue_biomass), and
	  // the quantity of complement (complement_biomass)
	  // ufl
	  float  ufl <- pasture_biomass    * pbiomass2ufl[month] +
	  				residue_biomass    * rbiomass2ufl +
	  				complement_biomass * cbiomass2ufl; // UFL from all sources
	  // draught milk from ufl
	  milk <- max([0, (ufl - upkeep_ufl*day_per_month) / ufl2liter]); // minus maintenance times ufl productivity
	  // produced milk
	  if (htype = "minifarm") {
	  	milk <- milk - mf_veal_need;
	  } else {
	  	milk <- milk * draught2produced;
	  }
	  
//	  if (htype = "minifarm") { write "->" + self + " real production:" + milk/day_per_month+"("+ufl+","+complement_biomass+","+residue_biomass+","+pasture_biomass+")";}

	  if (trace) {write '    ' + htype + ': milk production: ' + milk + ' by ' + milking_nb + ' cows';}
	}

	// rainy season is august, september and october
	bool is_rainy_season(int month) {
		if (month >= 0 and month <= 3) {return true;} else {return false;}
	}
	// transhumance decision algorithm
	bool herd_transhumance_decision(int month) {
		if (collectPoint = nil and month >= 4 and month <= 6) {  // november to january and if not collecting milk
		  float alea <- rnd(0.0,1.0);
		  if (htype = "small"  and alea < small_probability  / 100) {
		    return true;
		  }
		  if (htype = "medium" and alea < medium_probability / 100) {
		    return true;
		  }
		  if (htype = "large"  and alea < large_probability  / 100) {
		    return true;
		  }
	  }
	  return false;
	}
	// milk distribution
	action herd_distribute_milk(int month) {
		if (not transhumance and milking_nb > 0) {  // if there is some milk
		  // total available
		  float remaining_milk <- milk*milking_nb;
		  //auto-consumption
		  if (htype="small" or htype="minifarm") {
		  	consumed <- min([remaining_milk,small_consumption]);
		  } else if (htype = "medium") {
		  	consumed <- min([remaining_milk,medium_consumption]);
		  } else if (htype = "large") {
		  	consumed <- min([remaining_milk,large_consumption]);
		  }
		  remaining_milk <- remaining_milk - consumed;
		  // collected milk
		  if (remaining_milk > 0) {
		    if (collectPoint!=nil) {            // collect point in vicinity
		      if (roadAround) {                 // but road
		        // half to the market
		        market_milk <- market_milk + remaining_milk / 2;
		        income      <- income + (market_prices[month] * remaining_milk / 2);
		        // half to the collect point
		        ask collectPoint { do collectpoint_collect_milk(remaining_milk / 2); }
		        income      <- income + (collected_price * remaining_milk / 2);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', ' + remaining_milk / 2 + ',' + remaining_milk / 2;}
		      } else {                          // and no road
		      	// all to the collect point
		        ask collectPoint { do collectpoint_collect_milk(remaining_milk);}
		        income      <- income + (collected_price * remaining_milk);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', 0,' + remaining_milk;}
		      }
		    } else {                            // no collect point
		      if (roadAround) {  // but road
		        // half to the market
		        market_milk <- market_milk + remaining_milk / 2;
		        income      <- income + (market_prices[month] * remaining_milk / 2);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', ' + remaining_milk / 2 + ',0';}
		      }
		    }
		  }
		}
	}
	// the total carbon impact of the herd and consumed biomass for milk production
	action herd_carbon_impact(int month) {
	  if (milk > 0) {
	    // pastoral and crop residue biomass contribution
	    hcarbon_impact <- (total_pb_consumed * pasture_ci + total_crb_consumed * crop_residue_ci + total_cb_consumed * complement_ci);
	    // methane emission contribution
	    hcarbon_impact <- hcarbon_impact + (total_pb_consumed + total_crb_consumed + total_cb_consumed) * methane_coefficients[month];
	  	if (trace) {write '    ' + htype + ': carbon impact: ' + hcarbon_impact;}
	  } else {
	  	hcarbon_impact <- 0.0;
	  }
	}

	// DISPLAY
	aspect default {
		if (htype = "minifarm") {
			draw mfShape size: herd_size*10;
		} else if (transhumance) {
			draw tcowShape size: herd_size*10;
		} else {
			draw cowShape size: herd_size*10;
		}
	}
}

// the CSP species
species CSP {
	
	// Display
	aspect default {
		draw circle(300) color: rgb(0, 255, 255);
	}
}

// the collect points species
//species CollectPoint parent: graph_node edge_species: edge_agent {
species CollectPoint {
  	// The attributes
  	float      cmilk <- 0.0;   // collected milk
  	bool         csp <- false; // is this collectPoints a csp (distributing crop residue)
  	list<Herd> herds <- [];    // the herds contributing to this collect point
  	
  	// as a graph node
    bool related_to (graph_node other) {
    	return herds contains other;
    }
    
    action collectpoint_collect_milk(float milk) {
    	cmilk <- cmilk + milk;
    }
    
	// Display
	aspect default {
		draw cpShape size: 750;
	}
}

// the milkery species
species Milkery {
	
	// Display
	aspect default {
		draw ldbShape size: 1500;
	}
}

// the patch species
grid patch width: shape.width / patch_length height: shape.height / patch_length neighbors: 4 {
  	// The attributes
  	string cover <- "rien";   // "eau", "paturage1" (haute prod.) "paturage2" (faible prod.) "champs1" (haute prod.) "champs2" (faible prod.) "ville" "piste" "route" "forage" "pointCollecte" "rien"
  	rgb    color <- #white;
  	float  biomass <- 0.0;    // quantity of available biomass (uniform in this simulation)

	// DISPLAY
	aspect default {
		draw shape color: color border: #black;
	}
 
}

// THE EDGE COMPONENT
species edge_agent parent: base_edge {
    aspect base {
    	draw shape color: #blue;
    }
}

// THE MAP COMPONENTS
species IntensiveCropShape {		// Intensive crop areas
	int height;
	aspect default {
		draw shape color: #darkgreen depth: height;
	}
}
species IrrigatedCropShape {		// Irrigated crop areas
	int height;
	aspect default {
		draw shape color: #green depth: height;
	}
}
species PluvialCropShape {		// Pluvial crop areas
	int height;
	aspect default
	{
		draw shape color: #lightgreen depth: height;
	}

}
// the milkery infrastructure
species CircuitShape {			// les circuits de collecte
	string nomCircuit;
	aspect default {
		draw shape color: #grey depth: 15 + rnd(180);
		// draw text: string(nomCircuit) size: 10;
	}
}
// hydrological infrastructure
species WellShape {				// the wells
	aspect default {
		draw shape color: #blue;
	}
}
species SurfaceWaterShape {		// the permanent surface water
	aspect default {
		draw shape color: #darkblue depth: 11 + rnd(180) ;
	}
}
species PondShape {				// the ponds
	aspect default {
		draw circle(300) color: rgb(0, 255, 255);
	}
}
// the road infrastructure
species RoadShape { 				// the main roads
	aspect default {
		draw shape color: #black depth: 15 + rnd(180);
	}
}
species TrackShape { 			// the tracks and main road
	aspect default {
		draw shape color: #darkgrey depth: 15 + rnd(180);
	}
}

experiment main type: gui {
	init {
		rng <- "mersenne";
		seed <- float(154787);                      // (not so) big prime number
		loop times: 4 * 2048 { int x <- rnd(10);}   // generator warm up
	}
	
	parameter 'Fichier paramètre'  var: parameter_name category: 'Simulation' init: "../includes/parameters1.v6.json";
	parameter 'Trace'              var: trace          category: 'Simulation' init: false;
	parameter 'Fichier sauvegarde' var: save_name      category: 'Simulation' init: "../results/simulation.csv";
	parameter 'Sauvegarde'         var: save           category: 'Simulation' init: false;
	
	// Structure des mini fermes
  	parameter 'Nb de mini fermes'             var: nb_minifarms       category: "Laiterie" min: 0 max: 100 init: 15;
  	parameter 'Nb de CSPs'                    var: cspNumber          category: "Laiterie" min: 0 max: 100 init: 17;
  	// Paramètres économiques
	parameter 'Prix des résidus (CFA/kg)'     var: crop_residue_price category: "Paramètres économiques" min: 0 max: 100 init:30;
	parameter 'Prix du lait livré (CFA/l)'    var: delivered_price    category: "Paramètres économiques" min: 0 max: 600 init: 320;
	parameter 'Prix du lait collecté (CFA/l)' var: collected_price    category: "Paramètres économiques" min: 0 max: 600 init: 380;

	output {
		// the vectorial map for having an idea
		display CarteVectorial type: java2D {
			species IntensiveCropShape aspect: default refresh:false;
			species IrrigatedCropShape aspect: default refresh:false;
			species PluvialCropShape   aspect: default refresh:false;
			species CircuitShape       aspect: default refresh:false;
			species WellShape          aspect: default refresh:false;
			species PondShape          aspect: default refresh:false;
			species RoadShape          aspect: default refresh:false;
			species TrackShape         aspect: default refresh:false;
			species SurfaceWaterShape  aspect: default refresh:false;
			species CSP                aspect: default refresh:false;
		}

		// the created grid with the herds
		display Grille type: java2D {
			species patch         aspect: default refresh: true;
			species CollectPoint  aspect: default;
			species CSP           aspect: default;
			species Milkery       aspect: default;
			species Herd          aspect: default;
		}
		

		// The plots
		display Production refresh: every(1 #cycle)
		{
			// productivité laitière de la biomasse
			chart "Productivité de la biomasse" type: series size: { 1, 0.33 } position: { 0, 0.0 } y_label: 'kg/l' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "biomasse" value: biomass4milk style: line color: # black;
			}
			// graphe lait produit par troupeau
			chart "Production laitière" type: series size: { 1, 0.33 } position: { 0, 0.33 } y_label: 'l/tête/mois' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "traditionnel" value: milk4traditional style: line color: # black;
				data "collecté"     value: milk4collected   style: line color: # green;
				data "mini ferme"   value: milk4minifarm    style: line color: # red;
			}
			// graphe distribution du lait
			chart "Distribution du lait" type: series size: { 1, 0.33 } position: { 0, 0.66 } y_label: 'l/mois' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "marché"           value: milk2market          style: line color: # black;
//				data "produit"          value: producedMilk         style: line color: # orange;
				data "collecté"         value: milk2milkery         style: line color: # green;
				data "autoconsommé"     value: milk2autoconsumption style: line color: # red;
			}

		}
 
		display Impacts refresh: every(1 #cycle)
		{
			// impact économique
			chart "Impact économique (traditionnel)" type: series size: { 1, 0.25 } position: { 0, 0.0 } y_label: 'CFA' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "Revenu"  value: traditionalIncome                    style: line color: # red;
				data "Dépense" value: traditionalExpense                   style: line color: # orange;
				data "Bilan"   value: traditionalIncome-traditionalExpense style: line color: # darkred;
			}
			chart "Impact économique (collecté)" type: series size: { 1, 0.25 } position: { 0, 0.25 } y_label: 'CFA' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "Revenu"  value: collectedIncome                  style: line color: # red;
				data "Dépense" value: collectedExpense                 style: line color: # orange;
				data "Bilan"   value: collectedIncome-collectedExpense style: line color: # darkred;
			}
			chart "Impact économique (mini-ferme)" type: series size: { 1, 0.25 } position: { 0, 0.5 } y_label: 'CFA' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "Revenu mini ferme"    value: minifarmIncome                 style: line color: # red;
				data "Dépense mini ferme"   value: minifarmExpense                style: line color: # orange;
				data "Bilan mini ferme"     value: minifarmIncome-minifarmExpense style: line color: # darkred;
			}
			// impact carbone
			chart "Impact carbone" type: series size: { 1, 0.25 } position: { 0, 0.75 } y_label: 'kgCO2/l' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "Lait produit"  value: producedCI  style: line color: # black;
				data "Lait collecté" value: collectedCI style: line color: # red;
			}

		}

		display Troupeaux refresh: every(1 #cycle)
		{
			// graphe des biomasses
			chart "Biomasse pastorale" type: series size: { 1, 0.33 } position: { 0, 0 } y_label: 'kg/ha' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "biomasse par ha"    value: current_biomass style: line color: # green;
				data "biomasse par tête"  value: biomassHead     style: line color: # black;
				data "limite de faim"     value: starving_limit  style: line color: # red;
				data "besoin minimal"     value: maximum_consumption_zebu*day_per_month style: line color: # orange;
			}
			// densité
			chart "Densité des bêtes" type: series size: { 1, 0.33 } position: { 0, 0.33 } y_label: 'tête/ha' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "densité" value: cowDensity style: line color: # black;
			}
			// troupeaux
			chart "Nombre de tête" type: series size: { 1, 0.33 } position: { 0, 0.66 } y_label: 'tête' x_label: 'mois' x_serie_labels: months[monthNb]
			{
//				data "total"       value: cowNb              style: line color: # black;
				data "allaitantes" value: milkingNb          style: line color: # red;
				data "collectées"  value: collectedMilkingNb style: line color: # orange;
			}

		}

		display Consommations refresh: every(1 #cycle)
		{
			// graphe des biomasses
			chart "Biomasses (mini-fermes)" type: series size: { 1, 0.33 } position: { 0, 0 } y_label: 'kg/tête' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "pastoral"    value: pastoral4minifarm   style: line color: # green;
				data "résidu"      value: residue4minifarm    style: line color: # orange;
				data "complément"  value: complement4minifarm style: line color: # brown;
				data "total"       value: pastoral4minifarm+residue4minifarm+complement4minifarm style: line color: # black;
				data "limit"       value: maximum_consumption_metisse * day_per_month style: line color: # yellow;
			}
			// densité
			chart "Biomasses (collecté)" type: series size: { 1, 0.33 } position: { 0, 0.33 } y_label: 'kg/tête' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "pastoral"    value: nmPastoral4collected   style: line color: # blue;
				data "pastoral (laitière)"  value: pastoral4collected   style: line color: # green;
				data "résidu"      value: residue4collected    style: line color: # orange;
				data "complément"  value: complement4collected style: line color: # brown;
				data "total"       value: pastoral4collected+residue4collected+complement4collected style: line color: # black;
				data "limit"       value: maximum_consumption_zebu * day_per_month style: line color: # yellow;
			}
			// troupeaux
			chart "Biomasses (traditionnel)" type: series size: { 1, 0.33 } position: { 0, 0.66 } y_label: 'kg/tête' x_label: 'mois' x_serie_labels: months[monthNb]
			{
				data "pastoral"    value: nmPastoral4others   style: line color: # blue;
				data "pastoral (laitière)"    value: pastoral4others   style: line color: # green;
				data "résidu"      value: pastoral4others   style: line color: # orange;
				data "complément"  value: complement4others style: line color: # brown;
				data "total"       value: pastoral4others+residue4others+complement4others style: line color: # black;
				data "limit"       value: maximum_consumption_zebu * day_per_month style: line color: # yellow;
			}

		}

		//affiche les ecran 
		//deja dans l'on peut afficher des ecran sur les variables sans le mettre en place soit même
		monitor "saison"            value: season;
		monitor "année"             value: yearNb;
		monitor "mois"              value: months[monthNb];
	}
}




