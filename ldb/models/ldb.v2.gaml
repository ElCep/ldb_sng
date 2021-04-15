/***
* Name: ldbv2
* Author: jpmuller
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ldbv2


global {
  // GLOBAL VARIABLES
  // constants
  float patch_length <- 500.0;       // the patch size in m
  float average_small_herd_size;     // average size of a small herd
  float small_herd_sd;               // small herd size standard deviation
  float average_medium_herd_size;    // average size of a medium herd
  float medium_herd_sd;              // medium herd size standard deviation
  float average_large_herd_size;     // average size of a large herd
  float large_herd_sd;               // large herd size standard deviation
  int   day_per_month <- 30;		 // nb of days per month
  list<string>      months;               // list of months
  list<string>      seasons;              // list of season qualities
  list<int>         milking_percentages;  // percentage of milking cows within a herd by month
  list<float>       biomass2ufl;          // converts 1 kg of pasture biomass into corresponding UFL
  float             rbiomass2ufl;         // converts 1 kg of residue biomass into corresponding UFL
  float             ufl2liter;            // liter of milk produced by 1 ufl
  float             draught2produced;     // milk produced from draught milk (accounting veal need)
  list<float>       market_prices;        // price of milk on the market depending on the month
  list<float>       methane_coefficients; // methane emission coefficients for consumed biomass per month
  list<list<float>> biomass_percentages;  // for each month, the total availability of biomass as percentage of the pic
                                          // and the percentage really usable
  // computed constants
  float patch_surface;         		 // the surface of a patch in ha
  float grass_surface;               // the surface of the grassland
  point milkery_patch;               // the point where the milkery is
  // variables changing throughout the simulation
  int    cow_nb;                     // the total number of cows (depends on transhumance)
  float  market_milk;                // milk sold on market
  string season;                     // current season
  string season_1 ;                  // previous season (if the previous season was bad, there is half less milking cows)
  float  current_biomass;            // current biomass potential per ha for this month
  float  produced_carbon_impact;     // the total carbon impact of produced milch
  float  collected_carbon_impact;    // the total carbon impact of collected milch
  
  // various counters for statistics
  int nb_herd_stock;				 // the number of herds making stocks
  
  // the files
  // road infrastructure
  file roads        <- file("../includes/Routes.shp");         // roads
  file tracks       <- file('../includes/Routes_pistes3.shp'); // tracks
  // hydraulic infrastructure
//  file ponds  <- file('../includes/mareCadre.shp');          // ponds
  file surfaceWater <- file('../includes/Hydro1.shp');         // surface water
  file wells <- file('../includes/forage-sel.shp');            // wells
  // crops
  file pluvialCrop   <- file('../includes/Pluvial.shp');       // pluvial crop (mainly rice)
  file irrigatedCrop <- file('../includes/Irrigue.shp');       // irrigated crop (mainly rice)
  file intensiveCrop <- file('../includes/AgroI.shp');         // intensive crop (mainly sugar cane)
  // milkery infrastructure
  file milkery       <- file('../includes/Centre.shp');        // the milkery
  file collectPoints <- file('../includes/PC.shp');            // the collect points
//  file CSPs          <- file('../includes/CSP.shp');
//  file circuits      <- file('../includes/circuits2.shp');
  file bounds        <- file('../includes/deli.shp');          // the bounds of the space to take into account
  geometry shape     <- geometry(bounds).envelope;             // the bounds of the whole system
  
  // files containing shapes for drawing
  file ldbShape  <- file('../images/ldb.png');    // Laiterie du Berger
  file cpShape   <- file('../images/PC.png');     // collect point
  file cowShape  <- file('../images/vache2.png'); // herd
  file tcowShape <- file('../images/vache3.png'); // herd in transhumance
  file mfShape   <- file('../images/vache.png');  // minifarm
  
  // ecological parameters
  float bad_pic_biomass    <- 710.0;
  float good_pic_biomass   <- 2020.0;
  float medium_pic_biomass <- 1030.0;
  int cspNumber <- 17;
  // herd structure
  float herd_density    <- 0.5;
  int percentage_small  <- 25;
  int percentage_medium <- 45;
  int percentage_large  <- 30;
  // herd and minifarm typology
  int   nb_minifarms       <- 30;
  int   min_mf_herd_size   <- 6;
  int   max_mf_herd_size   <- 6;
  float min_mf_milk_prod   <- 5.0;
  float max_mf_milk_prod   <- 10.0;
  float collect_radius     <- 5.0;
  float water_radius       <- 5.0;
  float residue_radius     <- 10.0;
  // carbon impact parameters
  float pasture_ci      <- -0.49;
  float crop_residue_ci <- 0.04;
  float moto_ci         <- 0.05;
  float car_ci          <- 0.20;
  // zootechnical parameters
  int   cow_ingestion_ratio <- 50 ;
  float maximum_consumption <- 6.25; // maximum consumption per day (kg)
  int   complement_limit    <- 20;   // maximum of complement per day (kg)
  int   starving_limit      <- 90;   // minimum necessary per month
  float upkeep_ufl          <- 2.5;  // UFL for animal upkeep per day
  float crop_residue_stock  <- 1000.0;
  // economic parameters
  int crop_residue_price <- 50;
  int collected_price    <- 300;
  int delivered_price    <- 340;
  // milk autoconsumption parameters
  int small_consumption  <- 1;
  int medium_consumption <- 3;
  int large_consumption  <- 6;
  // transhumance probability
  int small_probability  <- 10;
  int medium_probability <- 30;
  int large_probability  <- 80;
  bool trace <- false;
  
  // some optimization
  list<patch> waterPatches     <- [];  // the list of patches where there is surface water
  list<patch> cropPatches      <- [];  // the list of patches where there is crop residue available;
  list<patch> roadPatches      <- [];  // the list of patches where there is a road or track;
  list<patch> pastoralPatches  <- [];  // the list of patches where there is pasture;
  
  // initialization
  init {
	  // constants
	  patch_surface <- patch_length * patch_length / 10000 ; // ha per patch
	  average_small_herd_size <-   7.42; // average size of a small herd
	  small_herd_sd <-             7.74; // small herd size standard deviation
	  average_medium_herd_size <- 36.45; // average size of a medium herd
	  medium_herd_sd <-            9.6;  // medium herd size standard deviation
	  average_large_herd_size <- 117.91; // average size of a large herd
	  large_herd_sd <-            68.85; // large herd size standard deviation
	  months <-               ["July", "August", "September", "October", "November", "December", "January", "February",
	                           "March", "April", "May", "June"];
	  // percentage of milking cows within a herd by month [July -> June]
	  milking_percentages <-  [10, 30, 30, 30, 20, 20, 20, 20, 20, 10, 10, 10];
	  // for each month, the total availability of biomass as percentage of the pic
	  // and the percentage really usable (not used yet)
	  biomass_percentages <-  [[0.18,	 9.74], [0.21,	 6.15], [1,	    5.21], [0.61,	5.12], [0.42,	 6.50], [0.31,	12.12],
	                           [0.20,	13.47], [0.15,	16.32], [0.11,	9.07], [0.07,	8.23], [0.04,	15.51], [0.03,	79.75]];
	  // conversion of 1 kg of pasture biomass into corresponding UFL depending on the month
	  biomass2ufl  <-          [0.7, 0.8, 0.8, 0.7, 0.6, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
	  // conversion of 1 kg of residue biomass into corresponding UFL
	  rbiomass2ufl <- 0.5;
	  // converion of 1 UFL to milk liters
	  ufl2liter        <- 0.4;
	  // conversion from draught milk to produced (human used) milk
	  draught2produced <- 0.5;
	  // evolution of milk market price
	  market_prices <-        [400.0, 350.0, 300.0, 250.0, 250.0, 250.0, 250.0, 250.0, 500.0, 600.0, 600.0, 500.0];
	  // methane emission depending on the eated biomass
	  methane_coefficients <- [625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0, 625.0];
	  seasons <-              ["bad", "medium", "good"]; // list of season qualities
	  // real variables
	  market_milk <-   0.0;                 // initial marketed milk quantity
  	  produced_carbon_impact  <-   0.0;     // the total carbon impact of produced milch
  	  collected_carbon_impact <-   0.0;     // the total carbon impact of collected milch
	  // initialization
	  do init_climate();                                 // sets the season and previous season
	  do init_env();
	  do init_milkery();
	  do init_collectPoints();
	  do init_herds();
  	  write 'Initialization completed.';
	}
	
	action init_climate { // sets the season and previous season
  		write 'Climate';
  		// init season
  		season_1 <- "medium";
  		season   <- one_of(seasons);
  		write '  Current season: '+season;
  	}

	action init_env { // initialize the environment
  		write 'Environment';
		// ENVIRONNEMENT FROM SHAPEFILES
		// pluvial crop areas
		create PluvialCropShape from: pluvialCrop {
			height <- 10 + rnd(90);
		}
		// zone irrigue (culture de riz)
		create IrrigatedCropShape from: irrigatedCrop {
			height <- 10 + rnd(90);
		}
		// Agriculture intensive
		create IntensiveCropShape from: intensiveCrop {
			height <- 10 + rnd(90);
		}
		// the main road
		create RoadShape from: roads;
		// the tracks
		create TrackShape from: tracks;
		//mareCadre
//		create PondShape from: ponds;
		// the hydrological system
		create SurfaceWaterShape from: surfaceWater;
		// les forages
		create WellShape from: wells;
		// les circuits de collecte
//		create CircuitShape from: circuits;

		int grass_cnt <- 0;
		current_biomass <- compute_biomass(0,season);
		// set all to pastoral surface
		ask patch {  
			cover <- "paturage1";
			color <- #yellow;
			grass_cnt <- grass_cnt + 1;
			biomass <- current_biomass * patch_surface;
			add self to: pastoralPatches;
		}
		// remove everythig else
		ask patch overlapping union([geometry(IrrigatedCropShape),geometry(IntensiveCropShape)]) {
			cover <- "champs1";
			color <- #darkgreen;
			grass_cnt <- grass_cnt - 1;
			biomass <- 0.0;
			add self to: cropPatches;
		}
		ask patch overlapping geometry(PluvialCropShape) {
			cover <- "champs2";
			color <- #green;
			grass_cnt <- grass_cnt - 1;
			biomass <- 0.0;
			add self to: cropPatches;
		}
		ask patch overlapping geometry(SurfaceWaterShape) {
			cover <- "eau";
			color <- #darkblue;
			grass_cnt <- grass_cnt - 1;
			biomass <- 0.0;
			add self to: waterPatches;
		}
		ask patch overlapping geometry(TrackShape) {
			cover <- "piste";
			color <- #darkgrey;
			grass_cnt <- grass_cnt - 1;
			biomass <- 0.0;
			add self to: roadPatches;
		}
		ask patch overlapping geometry(RoadShape) {
			cover <- "route";
			color <- #black;
			grass_cnt <- grass_cnt - 1;
			biomass <- 0.0;
			add self to: roadPatches;
		}
		grass_surface <- grass_cnt * patch_surface;
		write '  Shape: ' + shape;
 		write '  Number of patches: '+length(patch);		
 		write '    with '+length(pastoralPatches)+' pastoral patches';		
 		write '    with '+length(cropPatches)+' crop patches';		
 		write '    with '+length(waterPatches)+' water patches';		
 		write '    with '+length(roadPatches)+' road patches';		
  		write '  Grass surface (ha): '+grass_surface;		
	}

	action init_milkery {
		create Milkery from: milkery {
			milkery_patch <- self.location;
		}
  		write 'Milkery created';		
	}
	
	action init_collectPoints { // creates the collect points
		// creates them
		create CollectPoint from: collectPoints returns: _cps;
		// inits counter and ordered list of collect points from milkery
		int csp_count <- cspNumber;
		list<CollectPoint> cps <-  _cps sort_by (each.location distance_to milkery_patch);
		loop while: (!empty(cps) and csp_count > 0) {  // for each one
			ask    cps[0] { csp <- true; }
			remove cps[0] from: cps;
			csp_count <- csp_count - 1;
		}	
  		write 'CollectPoint created: ' + length(CollectPoint);		
	}

	action init_herds { //create the herds depending on the density and size distribution
  	  write 'Herds';
	  // herd type check
	  if (percentage_small + percentage_medium + percentage_large != 100) {
	    warn "The percentage of small, medium and large herds do not sum to 100%";
	    do pause();
	  }
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
	      smallNb <- smallNb + 1;
	    } else if (alea <= percentage_small + percentage_medium) {  // create medium herd
	      htype <- "medium";
	      herd_size <- int(ceil(gauss(average_medium_herd_size,medium_herd_sd)));
	      mediumNb <- mediumNb + 1;
	    } else {                                                    // create large herd
	      htype <- "large";
	      herd_size <- int(ceil(gauss(average_large_herd_size,large_herd_sd)));
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
	    milking_nb <- herd_milking_nb(0);
	    // remove the chosen patch
	    remove p from: lst;
	    // caches
	    cropAround <- !empty(cropPatches where (location distance_to each.location <= residue_radius#km));
	    if (cropAround) {cropNb <- cropNb + 1;}
	    roadAround <- !empty(roadPatches where (location distance_to each.location <= collect_radius#km));
	    if (roadAround) {roadNb <- roadNb + 1;}
	  }
  	  write '  Herds created: ' + nb_herds;
  	  write '    with ' + smallNb + ' small farms,';
  	  write '    with ' + mediumNb + ' medium farms,';
  	  write '    with ' + largeNb + ' large farms,';
  	  write '    and ' + collectedNb + ' farms linked to collect points,';
   	  write '        ' + cropNb + ' farms close to crop,';
   	  write '        ' + roadNb + ' farms close to road or track.';
  	  
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
	      milking_nb <- herd_milking_nb(0);
	      cnt        <- cnt - 1;
	    } else {
	    	do herd_make_stock();
	    }
	  }
	  write "  " + cnt + " mini-farms not allocated over " + nb_minifarms;
	  write "  " + nb_herd_stock + " herds made stock";
	  // computes the total number of cows generated for this simulation
	  do compute_cow_nb();
	  write "  " + cow_nb + " cows";
	}

	// an action to update the total number of cows in the simulation
	action compute_cow_nb {
	  cow_nb <- Herd where (!each.transhumance) sum_of (each.herd_size);
	}
	
	// EQUATIONS

	// computes the available biomass in a patch depending on the month
	// 0 -> July,...,11 -> June
	// and on the season quality
	// "bad", "medium", "good"
	float compute_biomass(int month, string current_season) {
	  float abiomass <- 0.0;
	  if (current_season = "bad")    { abiomass <- bad_pic_biomass;}
	  if (current_season = "medium") { abiomass <- medium_pic_biomass;}
	  if (current_season = "good")   { abiomass <- good_pic_biomass;}
	  list<float> percentages  <-  biomass_percentages[month]; // [%pic biomass %consumed]
	  abiomass <- abiomass * percentages[0];                   // total available biomass / ha
	  return (abiomass * percentages[1] / 100);
	}

	// DYNAMICS
	int monthNb <- 0;
	int yearNb  <- 0;
	
	// advances time (month and year)
	reflex nextStep {
		monthNb <- monthNb + 1;
		if (monthNb = 12) {	   // end of the year
			yearNb <- yearNb + 1;
			monthNb <- 0;
			if (yearNb = 11) { // end of the simulation
				do pause();
			}
			write "Year: " + yearNb + ", month: " + months[monthNb];
		    do new_climate;             // generates new season quality
		    nb_herd_stock <- 0;
		    ask Herd {					// all the herds comme back
		      transhumance <- false;
		      do herd_make_stock;       // possibly buy crop residue stock
		    }
			write "  " + nb_herd_stock + " herds made stock.";			
		} else {
			write "Year: " + yearNb + ", month: " + months[monthNb];			
		}
		do step;
	}
	
	// generates new season quality
	action new_climate {
	  season_1 <- season;
	  season   <- one_of(seasons);
	  write "  new season: " + season;
	}
	
	// One step simulation
	action step {
	  write "  Initialize income";			
	  ask Herd { // reset economic indicators
	  	income  <- 0.0;
	  	expense <- 0.0;
	  }    
	  // reset milk sold on market
	  write "  Initialize sold milk";			
	  market_milk <- 0.0;
	  // reset monthly collected milk
	  write "  Initialize collected milk";			
	  ask CollectPoint {
	    cmilk <- 0.0;
	  }
	  // current level of biomass per ha and then per patch
	  write "  Distribute biomass";			
	  current_biomass <- compute_biomass(monthNb,season);
	  ask pastoralPatches {
	    biomass <- current_biomass * patch_surface;
	  }
	  // computes the number of cows taking into account transhumance
	  do compute_cow_nb;
	  write "  " + cow_nb + " cows";
	  // monthly herd milk production
	  ask Herd {
	    // computes milk production with cost
	    do herd_produce_milk(monthNb);
	    // computes milk distribution with revenue
	    do herd_distribute_milk(monthNb);
	    // carbon balance of milk production for each herd
	    do herd_carbon_impact(monthNb);
	  }
	  // total carbon balance (including herd impact)
	  do total_carbon_impact;
	}
	
	action total_carbon_impact {
	  // carbon impact of each herd for milk production
	  float carbon_impact <- Herd sum_of (each.hcarbon_impact);
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
	  // total produced milk
	  float total_produced_milk <- Herd sum_of (each.milk);
	  // computes the carbon impact of the produced milk including its collection
	  if (total_produced_milk != 0) {
	    produced_carbon_impact <- carbon_impact / total_produced_milk;
	  }
	  // total collected milk
	  float total_collected_milk <- CollectPoint sum_of (each.cmilk);
	  // computes the carbon impact of the collected milk
	  if (total_collected_milk != 0) {
	    collected_carbon_impact <- (carbon_impact + herd_km * moto_ci + milkery_km * car_ci) / total_collected_milk;
	  }
	  write "  Carbon impact: " + produced_carbon_impact + ', ' + collected_carbon_impact;			
	}
	
}

// The herd species
// species Herd parent: graph_node edge_species: edge_agent {
species Herd {
  	// The attributes
  	string htype;             // "minifarm", "small", "medium", or "large"
  	bool transhumance;        // is the herd in transhumance or not
  	int herd_size;            // total number of cows
  	int milking_nb;           // number of milking cows
  	float stock;              // kg of crop residue
  	float stock_month;        // kg of crop residue available per month
  	float milk;               // monthly collected milk
  	float consumed;           // auto-consumption
  	float income;             // monthly income
  	float expense;			  // monthly expense
  	float hcarbon_impact;     // carbon impact of milk production
  	float total_pb_consumed;  // total quantity of consumed pastoral biomass
  	float total_crb_consumed; // total quantity of consumed crop residue biomass
  	CollectPoint collectPoint; // the collect point it is connected to
  	// some caches to speed up simulation
//  	bool milkeryAround      <- false;
  	bool cropAround;
  	bool roadAround;
//  	bool collectPointaround <- false;
  	
  	// as a graph node
    bool related_to (graph_node other) {
    	return collectPoint = other;
    }

	// DYNAMICS
	// possibly buy crop residue stock at the begining of the year
	action herd_make_stock {
	  // if there is possibility of crop residues around the herd
	  if (htype != "minifarm" and cropAround) {
	    stock       <- crop_residue_stock;                   // get the stock
	    expense     <- expense + stock * crop_residue_price; // pay the price...or maybe free ?
	    stock_month <- 0.0;                                  // not needed yet: distribution over the remaining year when starving starts
	    nb_herd_stock <- nb_herd_stock + 1;					 // update counter
	  }
	}
	// milk production
	action herd_produce_milk(int month) {
	  // milking cows
	  milking_nb <- herd_milking_nb(month); // number of milking cows
	  float pasture_biomass <- 0.0; 		// monthly consumed pasture biomass per head
	  float residue_biomass <- 0.0; 		// monthly consumed residue biomass per head
	  if (milking_nb > 0 and not transhumance) {
	    if (htype = "minifarm") {
	      float prod      <- rnd(min_mf_milk_prod,max_mf_milk_prod); // milk production per day and per head
	      float ufl       <- prod / ufl2liter + upkeep_ufl;          // ufl necessary for this production
	      residue_biomass <- ufl / draught2produced * day_per_month; // monthly residue biomass per head necessary for this production
	      expense <- expense + (residue_biomass * milking_nb * crop_residue_price); // cost of crop residue
	      milk    <- float(prod * day_per_month * milking_nb);                      // total milk production
	    } else {
	      // available pasture biomass per head per month
	      pasture_biomass <- current_biomass * grass_surface / cow_nb  * (cow_ingestion_ratio  / 100); 
	      // actually consumed pasture biomass
	      pasture_biomass <- min([pasture_biomass, maximum_consumption * day_per_month]);
	      // crop residue biomass from crops
	      if (pasture_biomass < maximum_consumption * day_per_month) {         // not enough
	        if (stock_month = 0) {                          // not used yet
	          stock_month <- stock / (12 - month);          // distribute on remaining months
	        }
	        residue_biomass <- min([stock_month / milking_nb, (pasture_biomass - maximum_consumption * day_per_month)]); // get the residue quantity per milking cow
	      }
	      // crop residue biomass from csp
	      if (collectPoint != nil and collectPoint.csp) {
	        float buy <- (maximum_consumption * day_per_month - pasture_biomass - residue_biomass);
	        if (buy > 0) { // the stock was not sufficient
		        residue_biomass <- residue_biomass + buy;
		        expense         <- expense + buy * crop_residue_price * milking_nb;
		    }
	      }
	      // if not enough biomass and good time to transhume
	      if ((pasture_biomass + residue_biomass) < starving_limit and herd_transhumance_decision(month)) {
	        // the herd goes out of the system for the next turn
	        transhumance    <- true;
	        // the herd goes out of the system now
	        //transhumance    <- true;
	        //pasture_biomass <- 0.0;
	        //residue_biomass <- 0.0;
	      }
	      // monthly production on all the milking cows
	      milk <- monthly_milk_production(pasture_biomass, residue_biomass, month) * milking_nb;
	    }
	  } else {
	    milk <- 0.0;
	  }
	  // total consumed biomass
	  total_pb_consumed  <- pasture_biomass * milking_nb;
	  total_crb_consumed <- residue_biomass * milking_nb;
	  if (trace) {write '    ' + htype + ': milk production: ' + milk + ' by ' + milking_nb + ' cows';}
	}
  	// computes the number of milking cows in a herd depending on the month
	// 0 -> July,...,11 -> June
	int herd_milking_nb(int month) {
	  if (htype = "minifarm") {
	    return herd_size;
	  } else {
	    float nb <- milking_percentages[month] * herd_size / 100;
	    // if the previous season was bad, there is half less milking cows
	    if (season_1 = "bad") {
	      return floor(nb / 2);
	    } else {
	      return floor(nb);
	    }
	  }
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
	// computes the monthly milk production per head given the ingested quantity
	// of pastoral biomass (pb) and the quantity of crop residue biomass (crb)
	float monthly_milk_production(float pb,float crb,int month) {
	  float  ufl <- pb * biomass2ufl[month] + crb * rbiomass2ufl;   // UFL from both sources
//	  write '' + pb + ", " + crb + ", " + ufl + ', ' + upkeep_ufl;
	  return max([0, (ufl - upkeep_ufl) * ufl2liter]);           // minus maintenance times ufl productivity
	}
	// milk distribution
	action herd_distribute_milk(int month) {
		if (milk > 0) {  // if there is some milk
		  // veal consumption
		  milk     <- ceil(milk * draught2produced);
		  // auto-consumption
		  consumed <- herd_consumed_milk();
		  milk     <- max([0,milk - consumed]);
		  // collected milk
		  if (milk > 0) {
		    if (collectPoint!=nil) {            // collect point in vicinity
		      if (roadAround) {                 // but road
		        // half to the market
		        market_milk <- market_milk + milk / 2;
		        income      <- income + (market_prices[month] * milk / 2);
		        // half to the collect point
		        ask collectPoint { cmilk <- cmilk + myself.milk / 2; }
		        income      <- income + (collected_price * milk / 2);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', ' + milk / 2 + ',' + milk / 2;}
		      } else {                          // and no road
		      	// all to the collect point
		        ask collectPoint { cmilk <- cmilk + myself.milk;}
		        income      <- income + (collected_price * milk);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', 0,' + milk;}
		      }
		    } else {                            // no collect point
		      if (roadAround) {  // but road
		        // half to the market
		        market_milk <- market_milk + milk / 2;
		        income      <- income + (market_prices[month] * milk / 2);
		  		if (trace) {write '    ' + htype + ': milk distribution: ' + consumed + ', ' + milk / 2 + ',0';}
		      }
		    }
		  }
		} else {
			consumed <- 0.0;
		}
	}
	// hard milk consumption per type
	float herd_consumed_milk {
	  if (htype = "minifarm") { return small_consumption;}
	  if (htype = "small")    { return small_consumption;}
	  if (htype = "medium")   { return medium_consumption;}
	  if (htype = "large")    { return large_consumption;}
	}
	// the total carbon impact of the herd and consumed biomass for milk production
	action herd_carbon_impact(int month) {
	  if (milk > 0) {
	    // pastoral and crop residue biomass contribution
	    hcarbon_impact <- (total_pb_consumed * pasture_ci + total_crb_consumed * crop_residue_ci);
	    // methane emission contribution
	    hcarbon_impact <- hcarbon_impact + (total_pb_consumed + total_crb_consumed) * methane_coefficients[month];
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
grid patch width: geometry(bounds).envelope.width / patch_length height: geometry(bounds).envelope.height / patch_length neighbors: 4 {
  	// The attributes
  	string cover <- "rien";   // "eau", "paturage1" (haute prod.) "paturage2" (faible prod.) "champs1" (haute prod.) "champs2" (faible prod.) "ville" "piste" "route" "forage" "pointCollecte" "rien"
  	rgb color <- #white;
  	float biomass <- 0.0;     // quantity of available biomass (uniform in this simulation)

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
	// Paramètres écologiques
	parameter 'Biomasse mauvaise année kg/ha' var: bad_pic_biomass    category: "Paramètres écologiques" min: 0.0 max: 2000.0;
	parameter 'Biomasse année moyenne kg/ha'  var: medium_pic_biomass category: "Paramètres écologiques" min: 0.0 max: 2000.0;
	parameter 'Biomasse bonne année kg/ha'    var: good_pic_biomass   category: "Paramètres écologiques" min: 0.0 max: 2000.0;
	// Structure des troupeaux
    parameter 'Densité des troupeaux vache/km2' var: herd_density   category: "Structure des troupeaux" min: 0.0 max: 3.0;
	parameter 'Pourcentage petit troupeau'  var: percentage_small   category: "Structure des troupeaux" min: 0 max: 100;
	parameter 'Pourcentage moyen troupeau'  var: percentage_medium  category: "Structure des troupeaux" min: 0 max: 100;
	parameter 'Pourcentage grand troupeau'  var: percentage_large   category: "Structure des troupeaux" min: 0 max: 100;
	// Structure des mini fermes
  	parameter 'Nb de mini fermes'                  var: nb_minifarms       category: "Structure des mini fermes" min: 0 max: 100;
  	parameter 'Distance au point de collecte (km)' var: collect_radius     category: "Structure des mini fermes" min: 0.0 max: 10.0;
    parameter "Distance à l'eau (km)"              var: water_radius       category: "Structure des mini fermes" min: 0.0 max: 10.0;
  	parameter "Distance aux résidus (km)"          var: residue_radius     category: "Structure des mini fermes" min: 0.0 max: 10.0;
  	// Paramètres carbone
	parameter 'Impact carbone pastoral (kgC/kg)' var: pasture_ci      category: "Paramètres carbone" min: -5.0 max: 5.0;
	parameter 'Impact carbone résidus (kgC/kg)'  var: crop_residue_ci category: "Paramètres carbone" min: -5.0 max: 5.0;
	parameter 'Impact carbone moto (kgC/km)'     var: moto_ci         category: "Paramètres carbone" min: -5.0 max: 5.0;
	parameter 'Impact carbone voiture (kgC/km)'  var: car_ci          category: "Paramètres carbone" min: -5.0 max: 5.0;
	// Paramètres zootechniques
  	parameter var: cow_ingestion_ratio category: "Paramètres zootechniques";
  	parameter "Consommation maximal (kg)" var: maximum_consumption category: "Paramètres zootechniques";
  	parameter "Limite complément (kg)" var: complement_limit    category: "Paramètres zootechniques";
  	parameter var: crop_residue_stock  category: "Paramètres zootechniques";
  	parameter "Limite de survie (kg)" var: starving_limit      category: "Paramètres zootechniques";
  	// Paramètres économiques
	parameter 'Prix des résidus (CFA/kg)'     var: crop_residue_price category: "Paramètres économiques" min: 0 max: 100;
	parameter 'Prix du lait livré (CFA/l)'    var: delivered_price    category: "Paramètres économiques" min: 0 max: 600;
	parameter 'Prix du lait collecté (CFA/l)' var: collected_price    category: "Paramètres économiques" min: 0 max: 600;
	// Paramètres de production laitière
	parameter 'UFL for maintenance'                 var: upkeep_ufl         category: "Paramètres laitiers" min: 0.0 max: 2.5;
	parameter 'Autoconsommation petit troupeau'     var: small_consumption  category: "Paramètres laitiers" min: 0 max: 10;
	parameter 'Autoconsommation troupeau moyen'     var: medium_consumption category: "Paramètres laitiers" min: 0 max: 10;
	parameter 'Autoconsommation grand troupeau'     var: large_consumption  category: "Paramètres laitiers" min: 0 max: 10;
	// Transhumance stratégie
	parameter 'Petit troupeau' var: small_probability  category: "Probabilités de transhumance" min: 0 max: 100;
	parameter 'Troupeau moyen' var: medium_probability category: "Probabilités de transhumance" min: 0 max: 100;
	parameter 'Grand troupeau' var: large_probability  category: "Probabilités de transhumance" min: 0 max: 100;

	output {
		// the vectorial map for having an idea
		display CarteVectorial type: opengl {
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
		display Grille type: opengl {
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
			chart "Productivité de la biomasse" type: series size: { 1, 0.33 } position: { 0, 0.0 } y_label: 'kg/l'
			{
				data "biomasse" value: int((Herd where (each.milk > 0)) sum_of ((each.total_pb_consumed + each.total_crb_consumed) / each.milk) / max([1,length(Herd where (each.milk > 0))])) style: line color: # black;
			}
			// graphe lait produit par troupeau
			chart "Production laitière" type: series size: { 1, 0.33 } position: { 0, 0.33 } y_label: 'l/tête/mois'
			{
				data "troupeau"   value: int((Herd where (each.htype != "minifarm" and each.milking_nb != 0)) sum_of (int(each.milk / each.milking_nb)) / length((Herd) where (each.htype != "minifarm"))) style: line color: # black;
				data "mini ferme" value: int((Herd where (each.htype  = "minifarm" and each.milking_nb != 0)) sum_of (int(each.milk / each.milking_nb)) / length((Herd) where (each.htype  = "minifarm"))) style: line color: # red;
			}
			// graphe distribution du lait
			chart "Distribution du lait" type: series size: { 1, 0.33 } position: { 0, 0.66 } y_label: 'l/mois'
			{
				data "marché"           value: int(market_milk) style: line color: # black;
//				data "produit"          value: int(Herd sum_of (each.consumed + each.milk)) style: line color: # yellow;
				data "collecté"         value: int(CollectPoint sum_of (each.cmilk)) style: line color: # green;
				data "autoconsommé"     value: int(Herd sum_of (each.consumed)) style: line color: # red;
			}

		}

		display Impacts refresh: every(1 #cycle)
		{
			// impact économique
			chart "Impact économique (traditionnel)" type: series size: { 1, 0.25 } position: { 0, 0.0 } y_label: 'CFA'
			{
				data "Revenu"  value: (Herd where (each.htype != "minifarm" and each.collectPoint = nil)) sum_of (each.income) / length(Herd where (each.htype != "minifarm" and each.collectPoint = nil)) 
				               style: line color: # darkgrey;
				data "Dépense" value: (Herd where (each.htype != "minifarm" and each.collectPoint = nil)) sum_of (each.expense) / length(Herd where (each.htype != "minifarm" and each.collectPoint = nil))
				               style: line color: # grey;
				data "Bilan"   value: (Herd where (each.htype != "minifarm" and each.collectPoint = nil)) sum_of (each.income - each.expense) / length(Herd where (each.htype != "minifarm" and each.collectPoint = nil)) 
				               style: line color: # black;
			}
			chart "Impact économique (collecté)" type: series size: { 1, 0.25 } position: { 0, 0.25 } y_label: 'CFA'
			{
				data "Revenu"  value: (Herd where (each.htype != "minifarm" and each.collectPoint != nil) sum_of (each.income)) / length(Herd where (each.htype != "minifarm" and each.collectPoint != nil)) style: line color: # darkgrey;
				data "Dépense" value: (Herd where (each.htype != "minifarm" and each.collectPoint != nil) sum_of (each.expense)) / length(Herd where (each.htype != "minifarm" and each.collectPoint != nil)) style: line color: # grey;
				data "Bilan"   value: (Herd where (each.htype != "minifarm" and each.collectPoint != nil) sum_of (each.income - each.expense)) / length(Herd where (each.htype != "minifarm" and each.collectPoint != nil)) style: line color: # black;
			}
			chart "Impact économique (mini-ferme)" type: series size: { 1, 0.25 } position: { 0, 0.5 } y_label: 'CFA'
			{
				data "Revenu mini ferme"    value: (Herd where (each.htype  = "minifarm") sum_of (each.income)) / length(Herd where (each.htype  = "minifarm")) style: line color: # red;
				data "Dépense mini ferme"   value: (Herd where (each.htype  = "minifarm") sum_of (each.expense)) / length(Herd where (each.htype  = "minifarm")) style: line color: # orange;
				data "Bilan mini ferme"     value: (Herd where (each.htype  = "minifarm") sum_of (each.income - each.expense)) / length(Herd where (each.htype  = "minifarm")) style: line color: # darkred;
			}
			// impact carbone
			chart "Impact carbone" type: series size: { 1, 0.25 } position: { 0, 0.75 } y_label: 'kgCO2/l'
			{
				data "Lait produit"  value: int(produced_carbon_impact)  style: line color: # black;
				data "Lait collecté" value: int(collected_carbon_impact) style: line color: # red;
			}

		}

		display Troupeaux refresh: every(1 #cycle)
		{
			// graphe des biomasses
			chart "Biomasse pastorale" type: series size: { 1, 0.5 } position: { 0, 0 } y_label: 'kg/ha'
			{
				data "biomasse pastorale" value: (pastoralPatches sum_of (each.biomass) / cow_nb) style: line color: # black;
				data "limite de faim"     value: starving_limit style: line color: # red;
				data "besoin minimal"     value: maximum_consumption*day_per_month style: line color: # green;
			}
			// densité
			chart "Densité des bêtes" type: series size: { 1, 0.5 } position: { 0, 0.5 } y_label: 'tête/ha'
			{
				data "densité" value: cow_nb / grass_surface style: line color: # black;
			}

		}

		//affiche les ecran 
		//deja dans l'on peut afficher des ecran sur les variables sans le mettre en place soit même
		monitor "année"             value: yearNb;
		monitor "mois"              value: months[monthNb];
		monitor "saison"            value: season;
		monitor "nbre de laitières" value: (Herd where (each.collectPoint != nil)) sum_of (each.milking_nb);
		monitor "nbre de vaches"    value: cow_nb;
	}
}




