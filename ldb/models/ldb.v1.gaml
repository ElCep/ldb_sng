/**
* Name: ldb.v1
* Authors: Oumarou Labo, Jean-Pierre Müller
* Description: model of the "Laiterie du Berger", North Senegal
* Tags: Tag1, Tag2, TagN
*/
model ldb


global
{
	
	//////////////////////////////MAJ\\\\\\\\\\\\\\\\\\\\\


///////////////code ajouter le 18/04/2019\\\\\\\\\\\\\\\\\\\\
	
	
	string nameCellPc;
	string pc_cspCellPc;
	point locationCellPC;
	bool is_Routes1CellPc;
	bool is_Routes2CellPc;
	
	
	//////////////////code ajoute le 06/10/2019\\\\\\\\\\\\\
	
	int prod_lait_Tr ;
	int prod_lait_Fr ;
	
	
	
	
//////////////////////////////MAJ


///////////////code ajouter le 12/02/2019
	int biotp;
	bool parallel <- true;

	// liste des types de cellules (leur nom en dit sur la geometrie dont elles sont juxtaposées
	list<cell> Cellbiomass;
	list<cell> CellHydro;
	list<cell> CellHydro1;
	list<cell> CellIrrigue;
	list<cell> CellForrage;
	list<cell> CellMarre;
	list<cell> CellRoute1; //pour la route
	list<cell> CellRoute2; //pour la piste
	list<cell> CellPc;
	list<cell> CellPc_csp;
	list<cell> CellCentre;
	list<cell> CellCsp;
	list<cell> CellPluvial;
	list<cell> CellAgro; //pour agriculture intensive
	float collectedMilk;

	// visualization management
	bool view_cover; //visualization cover or biomass

	//constants
	float patch_surface; //the surface of a patch in ha
	int patch_length; //the patch size in m
	//float herds_density; // nb of herds per km2
	float average_small_herd_size; // average size of a small herd
	float small_herd_sd; // small herd size standard deviation
	float average_medium_herd_size; // average size of a medium herd
	float medium_herd_sd; // medium herd size standard deviation
	float average_large_herd_size; // average size of a large herd
	float large_herd_sd; // large herd size standard deviation
	//float  months;// list of months
	list<int> milking_percentages; // percentage of milking cows within a herd by month
	list<list<float>> biomass_percentages; // for each month, the total availability of biomass as percentage of the pic
	// and the percentage really usable
	list<float> biomass2ufl; // converts 1 kg of pasture biomass into corresponding UFL
	list<int> market_prices; //price of milk on the market depending on the month
	list<int> methane_coefficients; //methane emission coefficients for consumed biomass per month
	list<string> seasons; //list of season qualities
	//  computed constants
	float grass_surface; // the surface of the grassland
	float cow_nb; // the total number of cows
	float milkery_patch; //the patch where the milkery is
	//variables changing throughout the simulation
	float market_milk; // milk sold on market
	string season; // current season
	string season_1; // previous season (if the previous season was bad, there is half less milking cows)
	float current_biomass; //current biomass potential per ha for this month
	float carbon_impact; // the total carbon impact of milch production
	int grass_cnt;
	int season_rnd;

	/////////////////parametre de scenarisation
	int bad_pic_biomass <- 710 parameter: "bad_pic_biomass";
	int good_pic_biomass <- 2020 parameter: "good_pic_biomass";
	int medium_pic_biomass <- 1030 parameter: "medium_pic_biomass";
	int nb_minifarms <- 30  parameter: "nombre de miniferme";
	float herd_density <- 0.5 parameter: "nombre de troupeau par km2";
	int minifarm_herd_size <- rnd(6,8) parameter: "minifarm_herd_size";
	int cnt;
	//////////////////////////////////MAJ\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	geometry the_line; //ligne troupeau-points de collecte
	int rnd; //variable à données aléatoire
	// variables pour l'affichage de la grille
	int heightImg const: true <- 5587;
	int widthImg const: true <- 6201;
	int nbMois; //nombre de mois
	int nbAnnee; //nomre d'annees
	float step <- 1.0 # months; //configuration du cycle
	int percentage_small <- 25 parameter: "percentage_small";
	int percentage_medium <- 45 parameter: "percentage_medium";
	int percentage_large <- 30 parameter: "percentage_medium";
	int cspNumber <- 17 parameter: "cspNumber";
	int crop_residue_price <- 50 parameter: "crop_residue_price";
	int collected_price <- 300 parameter: "collected_price";
	int delivered_price <- 340 parameter: "delivered_price";
	int milking_percentage <- 80 parameter: "milking_percentage";
	int small_probability <- 10 parameter: "small_probability";
	int medium_probability <- 30 parameter: "medium_probability";
	int large_probability <- 80 parameter: "large_probability";
	int cow_ingestion_ratio <- 50 parameter: "cow_ingestion_ratio";
	float maximum_consumption <- 6.0 parameter: "maximum_consumption";
	int complement_limit <- 20 parameter: "complement_limit";
	float crop_residue_stock <- 1000.0 parameter: "crop_residue_stock";
	int starving_limit <- 90 parameter: "starving_limit";
	float pasture_ci <- -0.49 parameter: "pasture_ci";
	float crop_residue_ci <- 0.04 parameter: "crop_residue_ci";
	float moto_ci <- 0.05 parameter: "moto_ci";
	float car_ci <- 0.20 parameter: "car_ci";
	int small_consumption <- 1 parameter: "small_consumption";
	int medium_consumption <- 3 parameter: "medium_consumption";
	int large_consumption <- 6 parameter: "large_consumption";
	float upkeep_ufl <- 2.5 parameter: "upkeep_ufl";
	int collect_radius <- 5 parameter: "collect_radius";
	int water_radius <- 5 parameter: "water_radius";
	int residue_radius <- 10 parameter: "residue_radius";
	list<string> months;
	bool gridbiomass <- false parameter: "gridbiomass";
	// Mise en place de la carte vectorielle	
	file Routes const: true <- file("../includes/Routes.shp");
	file Routes_pistes <- file('../includes/Routes_pistes3.shp');
	geometry shape <- envelope(Routes_pistes);
	int factorDiscret <- 45; //pour augmenter ou diminuer la taille des cellules
	file gif <- file('../images/vache.png'); //image Troupeau
	file ldb <- file('../images/ldb.png'); //image ldb
	file gif2 <- file('../images/vache2.png'); //image miniferme
	file PCimage <- file('../images/PC.png'); //a la place de la representation graphique du shape nous mettons une image pour avoir une similitude
	//avec la representation en netlogo

	// variabes globales relatives aux routes-pistes	
//	file Routes_pistes <- file('../includes/Routes-pistes.shp');

	// variabes globales relatives à Pluvial
	file Pluvial <- file('../includes/Pluvial.shp');

	// variabes globales relatives à Pluvial
	file PC <- file('../includes/PC.shp');

	// variabes globales relatives à Pluvial
	file CSP <- file('../includes/CSP.shp');

	// variabes globales relatives à Pluvial
	file Centre <- file('../includes/Centre.shp');

	// variabes globales relatives aux mare-cadre	
	file mareCadre <- file('../includes/mareCadre.shp');

	// variabes globales relatives à Hydro1
	file Hydro1 <- file('../includes/Hydro1.shp');

	// variabes globales relatives à Hydro
	file Hydro <- file('../includes/Hydro.shp');

	// variabes globales relatives à Hydro
	file Irrigue <- file('../includes/Irrigue.shp');

	// variabes globales relatives à forage-sel
	file forage_sel <- file('../includes/forage-sel.shp');

	// variabes globales relatives à Ferlo
	file Ferlo <- file('../includes/Ferlo.shp');

	// variabes globales relatives aux Circuits
	file Circuits <- file('../includes/circuits2.shp');

	// variabes globales relatives à AgroI
	file AgroI <- file('../includes/AgroI.shp');
	
	init
	{
	//////////////////////////////////MAJ\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


	///////////////code ajouter le 12/02/2019\\\\\\\\\\\\\\\\\\\\
	//Initialisation des cellules
		do init_biomasse();

		//classification des cellules
		Cellbiomass <- cell where (each.is_nobiomass = false);
		grass_cnt <- length(Cellbiomass);
		CellHydro <- cell where (each.is_Hydro);
		CellHydro1 <- cell where (each.is_Hydro1);
		CellIrrigue <- cell where (each.is_Irrigue);
		CellForrage <- cell where (each.is_Forrage);
		CellMarre <- cell where (each.is_Marre);
		CellPc <- cell where (each.is_PC);
		
		CellCentre <- cell where (each.is_Centre);
		CellCsp <- cell where (each.is_Csp);
		CellRoute1 <- cell where (each.is_Routes1);
		CellRoute2 <- cell where (each.is_Routes2);
		CellPluvial <- cell where (each.is_pluvial);
		CellAgro <- cell where (each.is_agro);

		// visualization management
		view_cover <- true;
		// constants
		patch_surface <- 6.25; // ha cellule fourage
		patch_length  <- 250; //patch size in m
		average_small_herd_size <- 7.42; //average size of a small herd
		small_herd_sd <- 7.74; //small herd size standard deviation
		average_medium_herd_size <- 36.45; //average size of a medium herd
		medium_herd_sd <- 9.6; //medium herd size standard deviation
		average_large_herd_size <- 117.91; //average size of a large herd
		large_herd_sd <- 68.85; //large herd size standard deviation
		months <- ["July", "August", "September", "October", "November", "December", "January", "February", "March", "April", "May", "June"];

		// percentage of milking cows within a herd by month [July -> June]
		milking_percentages <- [10, 30, 30, 30, 20, 20, 20, 20, 20, 10, 10, 10];
		// for each month, the total availability of biomass as percentage of the pic
		// and the percentage really usable (not used yet)
		biomass_percentages <-
		[[0.18, 9.74], [0.21, 6.15], [1, 5.21], [0.61, 5.12], [0.42, 6.50], [0.3, 12.12], [0.20, 13.47], [0.15, 16.32], [0.11, 9.07], [0.07, 8.23], [0.04, 15.51], [0.03, 79.75]];
		//conversion of 1 kg of pasture biomass into corresponding UFL depending on the month
		biomass2ufl <- [0.7, 0.8, 0.8, 0.7, 0.6, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
		// evolution of milk market price
		market_prices <- [400, 350, 300, 250, 250, 250, 250, 250, 500, 600, 600, 500];
		//methane emission depending on the eated biomass
		methane_coefficients <- [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
		seasons <- ["medium", "medium", "medium"]; //list of season qualities
		//real variables
		market_milk <- 0.0; //initial collect milk quantity
		carbon_impact <- 0.0; //initial carbon-impact
		// initialization
		// init-milkery
		//  init-climate                                      ; sets the season and previous season
		// init-env
		// init-collectPoints
		//  init-herds
		create init_climate;

		//calcul de la surface de paturage a l'initialisation
		grass_surface <- grass_cnt * patch_surface;
		//repatition uniforme de la biomasse a l'initialisation
		ask Cellbiomass
		{
			current_biomass <- compute_biomass(0, season);
			do biomass_patch();
		}

		// Pluvial
		create PluvialShape from: Pluvial
		{
			height <- 10 + rnd(90);
		}

		//routes pistes
		create Routes_pistesShape from: Routes;

		//routes
		create Routes_pistesShape2 from: Routes_pistes;

		//mareCadre
		create mareCadreShape from: mareCadre;

		// Hydro1
		create Hydro1Shape from: Hydro1 ;

		// Hydro
		create HydroShape from: Hydro;
		//zone irrigue(culture de riz
		create IrrigueShape from: Irrigue
		{
			height <- 10 + rnd(90);
		}

		//forage_sel
		create forage_selShape from: forage_sel;

		//Ferlo
		create FerloShape from: Ferlo;

		// Circuits
		create CircuitsShape from: Circuits;

		// Agriculture intensive
		create AgroIShape from: AgroI
		{
			height <- 10 + rnd(90);
		}

		//point de collecte
		create PointRencontreShape from: PC
		{
		}

		//CSP "ici pas utilise" car il ya possibilite d'augmenter leur nombre en fonction de conditiond lies a leur proximite avec la laiterie
		create cspShape from: CSP
		{
		}

		//nombre de troupeau
		float nb_herds <- (grass_surface / 100) * herd_density;

		//instanciation des troupeau
		create Troupeau number: nb_herds
		{
			transhumance <- false;
			if (percentage_small + percentage_medium + percentage_large != 100)
			{
				write "The percentage of small, medium and large herds do not sum to 100%";
			}

			//repartion selon une loi normale de la taille des troupeaux
			rnd <- rnd(0, 100);
			if (rnd <= percentage_small)
			{
				htype <- "small";
				herd_size <- ceil(gauss(average_small_herd_size, small_herd_sd/average_small_herd_size));
			} else if (rnd <= percentage_small + percentage_medium)
			
			{
				htype <- "medium";
				herd_size <- ceil(gauss(average_medium_herd_size, medium_herd_sd/average_medium_herd_size));
			} else
			{
				htype <- "large";
				herd_size <- ceil(gauss(average_large_herd_size, large_herd_sd/average_large_herd_size));
			}

			milking_nb <- herd_milking_nb(0); //nombre de laitiere a l'initialisation
			
			cnt <- nb_minifarms;

			location <- one_of(Cellbiomass).location;
			//proximite du troupeau  aux sources d'eau(lac de guiers, fleuve,marres et forages) 
			ask CellHydro
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(water_radius)))
				{
					myself.eauTrouve <- true;
				}

			}

			ask CellHydro1
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(water_radius)))
				{
					myself.eauTrouve <- true;
				}

			}

			ask CellForrage
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(water_radius)))
				{
					myself.eauTrouve <- true;
				}

			}

			ask CellMarre
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(water_radius)))
				{
					myself.eauTrouve <- true;
				}

			}

			//proximite a de la biomasse
			ask Cellbiomass
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(residue_radius)))
				{
					myself.champsTrouvebiomass <- true;
				}

			}

			//proximite aux cellules juxtaposant les zones en agriculture intensive
			ask CellAgro
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(residue_radius)))
				{
					myself.champsTrouve <- true;
				}

			}

			//proximite aux cellules juxtaposant les zones pluvieuses
			ask CellPluvial
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(residue_radius)))
				{
					myself.champsTrouve <- true;
				}

			}
			
			
				//point de collecte et centre
			ask CellRoute2
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(collect_radius)))
				{
						myself.Tr_Route2 <- true;

				}
				
			}
			
			
			//point de collecte et centre
			ask CellRoute1
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(collect_radius)))
				{
						myself.Tr_Route1 <- true;

				}
				
			}

			//point de collecte et centre
			ask CellPc
			{
				if (myself.location distance_to self.location <= ceil(km2patch_nb(collect_radius)))
				{
					if (myself.test = "ras")
					{
					//
						myself.test <- self.name;
						myself.pcTrouve <- true;
						link_neighbors <- true;
						myself.herd_kmT <- myself.location distance_to self.location;
					}

				}
				
				

				ask CellCentre
				{
					if (myself.location distance_to self.location <= ceil(km2patch_nb(30)))
					{
						myself.pc_csp <- name;
						myself.milkery_patch <- myself.location distance_to self.location;
					}

				}

			}

			//generation miniferme
			ask Troupeau
			{
				if (cnt > 0)
				{
					if (champsTrouve = true and eauTrouve = true and pcTrouve = true)
					{
						htype <- "minifarm";
						herd_size <- float(minifarm_herd_size);
						milking_nb <- herd_milking_nb(0);
						cnt <- cnt - 1;
					}

				}

			}

			cow_nb <- (Troupeau where (each.transhumance = false)) sum_of (each.herd_size);
		}
		//laiterie
		create centreShape from: Centre;
	}
	///////////////code ajouter le 12/02/2019\\\\\\\\\\\\\\\\\\\\


	//initialiser la biomasse et distinction de chaque cellule en fonction des elements geometrique de la carte vectorielle(eau, routes, paturage2 etc....)
	action init_biomasse
	{
		geometry shape2 <- geometry(mareCadre);
		geometry shape3 <- geometry(Hydro1);
		//geometry shape4 <- geometry(Hydro);
		//geometry shape5 <- geometry(Irrigue);
		geometry shapePluvial <- geometry(Pluvial);
		geometry shapeAgroI <- geometry(AgroI);
		geometry shape6 <- geometry(forage_sel);
		geometry shape7 <- geometry(Routes);
		geometry shape8 <- geometry(Routes_pistes);
		geometry shape9 <- geometry(PC);
		geometry shape10 <- geometry(Centre);
		geometry shape11 <- geometry(CSP);
		//parallelisme et juxtaposition(ou enchevauchement) des cellules à la carte vectrielle
		ask cell overlapping shape2 
		{
			is_nobiomass <- true;
			is_Marre <- true;
		}

		ask cell overlapping shape3 
		{
			is_nobiomass <- true;
			is_Hydro1 <- true;
			color <- # blue;
		}

	

		ask cell overlapping shapePluvial 
		{
			is_pluvial <- true;
			is_nobiomass <- true;
			color <- rgb(0, 255, 0);
		}

		ask cell overlapping shapeAgroI 
		{
			is_agro <- true;
			is_nobiomass <- true;
			color <- rgb(0, 83, 0);
		}

		ask cell overlapping shape6 
		{
			is_nobiomass <- true;
			is_Forrage <- true;
			color <- rgb(0, 64, 128);
		}

		ask cell overlapping shape7 
		{
			is_nobiomass <- true;
			is_Routes1 <- true;
			color <- # black;
		}

		ask cell overlapping shape8 
		{
			is_nobiomass <- true;
			is_Routes2 <- true;
			color <- rgb(128, 64, 64);
		}

		ask cell overlapping shape9 
		{
			is_nobiomass <- true;
			is_PC <- true;
		}

		ask cell overlapping shape10 
		{
			is_Centre <- true;
			is_nobiomass <- true;
		}

		ask cell overlapping shape11 
		{
			is_nobiomass <- true;
			is_Csp <- true;
		}
		ask cell 
		{
			if (is_nobiomass = false or is_PC = true or is_Marre = true)
				{
					color <- rgb(128, 128, 0);
				}
				
			if ((is_Routes2 = true) and (is_pluvial = true or is_Hydro = true or is_Hydro1 = true or is_Irrigue = true or is_nobiomass = false))
				{
					color <- rgb(128, 64, 64);
				}

				if ((is_Routes1 = true) and (is_pluvial = true or is_Hydro = true or is_Hydro1 = true or is_agro = true or is_Irrigue = true or is_Routes2 = true or is_nobiomass = false))
				{
					color <- # black;
				}
		}

	}

	//calcul  du nombre de têtes
	action compute_cow_nb
	{
		cow_nb <- (Troupeau where (each.transhumance = false)) sum_of (each.herd_size);
	}

	// gestion du climat
	action new_climate
	{
		season_1 <- season;
		season_rnd <- rnd(0, 2);
		season <- seasons[season_rnd];
	}
	
	//gestion carbone
	action total_carbon_impact
	{
		// ; carbon impact of each herd
		carbon_impact <- (Troupeau) sum_of (each.hcarbon_impact);

		//; computes the distance to each collected point in km
		int milkery_km <- 0;
		ask CellPc
		{
			if (cmilk != 0)
			{
			// ; computes the distance to each collected herd in km
				int herd_km <- 0;
				// ask link_neighbors 
				ask Troupeau  
				{
					if (test = myself.name)
					{
						herd_km <- herd_km + int(myself.patch_nb2km(int(self.location distance_to myself.location)));
					}
				}
					// ] 
					carbon_impact <- carbon_impact + (moto_ci * herd_km / cmilk);
					milkery_km <- milkery_km + int(patch_nb2km(int(milkery_patch)));
			}

		}

		//total_milk <- total_milk + cmilk;
		int total_milk <- int((CellPc) sum_of (each.cmilk));
		if (total_milk != 0)
		{
			carbon_impact <- carbon_impact + (car_ci * milkery_km / total_milk);
		}

	}

	// l'action appelant les autres actions dans un oradononcement précis
	action step (int Mois)
	{
		//  ; if new year (starting in july)
		if (Mois = 0)
		{
			do new_climate(); // ; generates new season quality
			ask Troupeau
			{
				transhumance <- false;
				do herd_make_stock(); // ; possibly buy crop residue stock
			}

		}
		// il faut que je fasse la mise a jour update-patches-view ,update-collectPoints-view ,update-herders-view
		market_milk <- 0.0;
		ask Cellbiomass
		{
			current_biomass <- compute_biomass(Mois, season);
			do biomass_patch();
		}

		// reset ly collected milk
		ask CellPc
		{
			cmilk <- 0.0;
			nameCellPc<- name;
			pc_cspCellPc <-pc_csp;
		}
		

		//; computes the number of cows taking into account transhumance
		do compute_cow_nb();
		//; monthly herd milk production
		
		ask cell
		{
			locationCellPC<-location;
			is_Routes1CellPc<-is_Routes1;
			is_Routes2CellPc<-is_Routes2;
			
		}
		
		// ; computes milk production with cost
		ask Troupeau
		{
			
			do herd_produce_milk(Mois);
			// ; computes milk distribution with revenue
			do herd_distribute_milk(Mois);
			//  ; carbon balance of milk production for each herd
			do herd_carbon_impact();

			//; total carbon balance (including herd impact)
		}
		// ; advance time
		//  ask herds [ set income 0 ]    ; resets income
		do total_carbon_impact();
		
		
		
		
	
	}

	//determine le temps a chaque cycle (par mois), et execute l'action step
	reflex calcul_temps
	{
		nbMois <- nbMois + 1;
		if (nbMois = 12)
		{
			nbMois <- 0;
			nbAnnee <- nbAnnee + 1;
		}

		if (nbMois = 12 and nbAnnee = 10)
		{
			do pause();
		}

		do step(nbMois);

		// pour eviter l'erreur qui apparait dans Netlogo au niveau du graphique" biomasse to produce milk" nous effectuer les calcules a ce niveau (aucun impact sur les resultats)
		ask Troupeau
		{
			if (milk > 0)
			{
				bioma <- (total_pb_consumed + (total_crb_consumed / milk));
				
			}

			biotp <- int((Troupeau where (each.milk > 0)) sum_of (each.bioma) / length(Troupeau where (each.milk > 0)));
			
		}
		//prod_lait_Tr <- int((Troupeau where (each.htype != "minifarm" and each.milking_nb != 0)) sum_of (int(each.milk / each.milking_nb)) / length((Troupeau) where	(each.htype != "minifarm")));
		//prod_lait_Fr <- int((Troupeau where (each.htype = "minifarm")) sum_of (int(each.milk / each.milking_nb)) / length((Troupeau) where (each.htype = "minifarm")));
		//save [prod_lait_Tr,prod_lait_Fr,months[nbMois]] to: "../results/prod_lait.csv" type:"csv" rewrite: false;
		//save [biotp,months[nbMois]] to: "../results/bio_prod_lait.csv" type:"csv" rewrite: false;
	}

}

species CollectPoint {
	float cmilk;  // collected milk
	bool csp;     // is this collect point a csp (distributing crop residue)
}

species Troupeau {
	// les variables du modèle NetLogo
	string htype;             // "minifarm", "small", "medium", or "large"
	bool transhumance;        // is the herd in transhumance or not
	float herd_size;          // total number of cows
	float milking_nb;         // number of milking cows
	float stock;              // kg of crop residue
	float stock_month;        // kg of crop residue available per month
	float milk;               // monthly producted milk
	float consumed;           // auto-consumption
	float income;             // monthly income
	float hcarbon_impact;     // carbon impact of milk production
	float total_pb_consumed;  // total quantity of consumed pastoral biomass
	float total_crb_consumed; // total quantity of consumed crop residue biomass
	
	// proximite du troupeau a des elements de la carte vectorielle(donc aux cellules les correspondants)
	bool pcTrouve;
	bool eauTrouve;
	bool champsTrouve;
	bool champsTrouvebiomass;
	float herd_kmT; //distance troupeau-point de collecte
	float bioma; //variable utilise pour  eviter l'erreur qui apparait dans Netlogo au niveau 
	//du graphique" biomasse to produce milk" nous effectuer les calcules a ce niveau (aucun impact sur les resultats)
	string test <- "ras"; //ppour l'application du principe de clé primaire et etrangere
	
	//les troupeaux proches de la route et pistes
	bool Tr_Route1;
	bool Tr_Route2;

	// lait donne a la laiterie
	float Tr_col;
	
	// Initializes the herd
	init {
		
	}
	
	// EQUATIONS
	// action nombre de laitiere
	float herd_milking_nb (int Mois)
	{
		if (self.htype = "minifarm")
		{
			return floor(herd_size * milking_percentage / 100);
		} else
		{
			float nb <- milking_percentages[Mois] * herd_size / 100;
			if (season_1 = "bad")
			{
				return floor(nb / 2);
			} else
			{
				return floor(nb);
			}

		}
	}

	//production jounaliere du lait
	float daily_milk_production (float pb, float crb, int Mois)
	{
		float ufl <- (pb * biomass2ufl[Mois]) + (crb * 0.5);
		return max([0.0, ((ufl - upkeep_ufl) * 0.5)]);
	}

	// possibly buy crop residue stock at the begining of the year
	action herd_make_stock
	{
		if (htype != "minifarm" and (champsTrouve = true or champsTrouvebiomass = true))
		// if there is possibility of crop residues around the herd
		{ // any? (patches in-radius km2patch-nb residue-radius) with [cover = "paturage2" or cover = "champs1" or cover = "champs2"] [
			stock  <- crop_residue_stock; //get the stock
			income <- income - stock * crop_residue_price; // pay the price...or maybe free ?
			stock_month <- 0.0; // not needed yet: distribution over the remaining year when starving starts
		}

	}

	//production mensuelle
	action herd_produce_milk (int mois)
	{
//		float aliment ;
//		int lait_vache_jour;
//		float aliment_par_noyau_laitier;
		milking_nb <- herd_milking_nb(mois);

		// number of milking cows
		if (milking_nb > 0.0 and transhumance = false)
		{
			if (htype = "minifarm")
			{
				int   prod <- 5 + rnd(0, 5); // milk production per day and per head
				float ufl <- prod / 0.5 + upkeep_ufl; //ufl necessary for this production
				float residue_biomass <- ufl / 0.5; //residue necessary for this production
				income <- income - residue_biomass * crop_residue_price * milking_nb;   //cost of crop residue
				milk   <- milking_nb * 30 * prod; //milk production

			} else {
			// pasture biomass
				float pasture_biomass <- current_biomass * grass_surface / cow_nb * (cow_ingestion_ratio / 100); // available pasture biomass
				//bio <- pasture_biomass;
				pasture_biomass <- min([pasture_biomass, maximum_consumption]); // real possible consumption

				//; crop residue biomass from crops
				float residue_biomass <- 0.0;
				if (pasture_biomass < float(complement_limit))
				{ // ; not enough
					if (stock_month = 0.0)
					{ // ; not used yet
						stock_month <- stock / (12 - mois); //distribute on remaining months

					}
					if ((stock_month / milking_nb) + pasture_biomass>=maximum_consumption)
					{
						residue_biomass <- maximum_consumption - pasture_biomass;
					}
					else
					{
						residue_biomass <- stock_month / milking_nb; // pas assez de residu pour toutes les VL
					}

					
				}
				//  ; crop residue from csp
				CellPc_csp<-CellPc where (test = each.name and each.pc_csp != "RAS");
					
					ask CellPc_csp
					{
						
						
							float buy <- (rnd(1,complement_limit) - pasture_biomass - residue_biomass);
							if(buy>0)
							{
								residue_biomass <- residue_biomass + buy;
								myself.income <- myself.income - buy * crop_residue_price * myself.milking_nb;
							}
							
					
					}


				//  ; if not enough biomass and between october and january
				//  let month (ticks mod 12)
				if ((pasture_biomass + residue_biomass) < starving_limit and mois >= 4 and mois <= 6 and herd_transhumance_decision() = true)
				{   //  the herd goes out of the system
					transhumance <- true;
					milk <- 0.0;
				} else
				{   // the herd is in the system and possibly producing
					total_pb_consumed <- pasture_biomass * milking_nb;
					total_crb_consumed <- residue_biomass * milking_nb;
					milk <- milking_nb * 30 * daily_milk_production(pasture_biomass, residue_biomass, mois);
				}

			}
			//pour sauvegarder dans un fichier csv
		//if(pcTrouve=true)
				//{
					//save [name,htype,milk,milking_nb,(milk/milking_nb)/30,months[nbMois],nbAnnee] to: "../results/bio_prod_lait3.csv" type:"csv" rewrite: false;
				//}
		} else
		{
			milk <- 0.0;
		}
		

	}

	// decision d'aller en transhumace
	bool herd_transhumance_decision
	{
		float random <- rnd(0.0, 1.0);
		if (htype = "small"  and random < small_probability / 100) {
			return true;
		}
		if (htype = "medium" and random < medium_probability / 100) {
			return true;
		}
		if (htype = "large"  and random < large_probability / 100) {
			return true;
		}
		return false;
	}

	// distribution du lait
	action herd_distribute_milk (int Mois)
	{
		income<-0.0;
		milk <- ceil(milk / 2);
		if (milking_nb > 0.0)
		{
			consumed <- herd_consumed_milk();
		}
		
		milk <- max([0.0, (milk - consumed)]);

		//; collected milk
		if (milk > 0.0)
		{
			
				
				
						if (pcTrouve=true)
						{
							if (Tr_Route2= true or Tr_Route1 = true)
							{
									market_milk <- milk / 2;
									income <- income + (market_prices[Mois] * milk / 2);
									Tr_col <-milk/2;
									ask CellPc where (test = each.name)
									{
										cmilk <- Troupeau where (each.test = self.name) sum_of(each.milk/2);
									}
									income <- income + (collected_price * milk / 2);
							} 
							else
							{
								ask CellPc where (test = each.name)
									{
										cmilk <- Troupeau where (each.test = self.name) sum_of(each.milk);
									}
									
								Tr_col <-milk;
								income <- income + (collected_price * milk);
							}
				
							//save [name,htype,milk,milking_nb,(Tr_col/milking_nb)/30,months[nbMois],nbAnnee] to: "../results/bio_prod_lait4.csv" type:"csv" rewrite: false;
				
						} else
						{
							if (Tr_Route2= true or Tr_Route1 = true)
							{
								Tr_col <-0.0;
								market_milk <- milk / 2;
								income <- income + (market_prices[Mois] * milk / 2);
							}

						}

		
		}

	}

	//consommation du lait
	float herd_consumed_milk
	{
		if (htype = "minifarm")
		{
			return small_consumption * 30;
		}

		if (htype = "small")
		{
			return small_consumption * 30;
		}

		if (htype = "medium")
		{
			return medium_consumption * 30;
		}

		if (htype = "large")
		{
			return large_consumption * 30;
		}
		

	}

	//impact carbonne
	action herd_carbon_impact
	{
		if (milk != 0.0)
		{
		//; pastoral biomass contribution
			hcarbon_impact <- ((total_pb_consumed * pasture_ci) + (total_crb_consumed * crop_residue_ci)) / milk;

			//; methane emission contribution
			// hcarbon_impact <- hcarbon_impact;
		}
		//set pcolor scale-color green biomass (good-pic-biomass / 2) 100;



	}

	aspect image
	{
		if(htype = "large") 
		{

		draw gif size: 2000;
		//	draw circle(400) color: # black;
		}

		if(htype = "medium")
		{
		draw gif size: 1300;
			//draw circle(370) color: # black;
		}

		if(htype = "small")
		{
		draw gif size: 900;
			//draw circle(300) color: # black;
		}

		if(htype = "minifarm")
		{
		draw gif2 size: 900;
			//draw circle(300) color: # red;
		}

			ask CellPc
			{
				if (myself.test = name)
				{
					draw line([myself.location, location]) color: # blue;
				}
			}
	}
}

//declaration des shape file pour creer l'environnement
species AgroIShape
{ int height;
	aspect default
	{
		draw shape color: rgb(180, 221, 165, 255) depth: height;
	}

}

species CircuitsShape
{
	string nomCircuit;
	aspect default
	{
		draw shape color: # red depth: 15 + rnd(180);
		// draw text: string(nomCircuit) size: 10;
	}

}

species FerloShape
{
	aspect default
	{
		draw shape color: # yellow;
	}

}

species forage_selShape
{
	aspect default
	{
		draw shape color: # red;
	}

}

species Hydro1Shape
{
	aspect default
	{
		draw shape color: # blue depth: 11 + rnd(180) ;
	}

}

species HydroShape
{	
	aspect default
	{
		draw shape color: # blue depth: 11 + rnd(180) ;
	}

}

species IrrigueShape
{	int height;
	aspect default
	{
		draw shape color: rgb(22, 243, 45) depth: height;
	}

}

species mareCadreShape
{
	aspect default
	{
	//draw shape color: # green;
		draw circle(300) color: rgb(0, 255, 255);
	}

}

species PluvialShape
{ int height;
	aspect default
	{
		draw shape color: rgb(243, 199, 37, 1.0) depth: height;
	}

}

species Routes_pistesShape
{
	aspect default
	{
		draw shape color: # black depth: 15 + rnd(180);
	}

}

species Routes_pistesShape2
{
	aspect default
	{
		draw shape color: # black depth: 15 + rnd(180);
	}

}

species init_climate
{
	init
	{
	//sets the season and previous season
	// init season
		season_1 <- "medium";
		season_rnd <- rnd(0, 2);
		season <- seasons[season_rnd];
	}

}

species PointRencontreShape
{
	aspect default
	{
		draw PCimage size: 750;
		//draw circle(100) color: # red;
	}

}

species cspShape
{
	aspect default
	{
		draw shape color: rgb(150, 12, 15);
	}

}

//définition du centre de collecte (la laiterie du berger)
species centreShape
{
	aspect default
	{
		draw ldb size: 1500;
	}

}

grid cell1 width: widthImg / factorDiscret  height: heightImg / factorDiscret 
{
	//peut etre la couleur
	rgb color <- rgb(128, 128, 0); //le fond est de coleur blanche
	
}

//la cellule avec sa dynamique
grid cell width: widthImg / factorDiscret height: heightImg / factorDiscret neighbors: 4 frequency: 0 use_regular_agents: false use_individual_shapes: false use_neighbors_cache:
false schedules: [] 
{
//apres je gere sa


//////////code ajoute le 12/02/2019\\\\\\\\\\
// parametre pour les zones irrigue, hydriques...
	bool trouve <- false;

	//biomass
	float biomass;
	
	bool is_nobiomass <- false;
	bool is_Hydro <- false;
	bool is_Hydro1 <- false;
	bool is_Irrigue <- false;
	bool is_Forrage <- false;
	bool is_Marre <- false;
	bool is_Routes1 <- false;
	bool is_Routes2 <- false;
	bool is_PC <- false;
	bool is_Centre <- false;
	bool is_Csp <- false;
	bool is_pluvial <- false;
	bool is_agro <- false;
	string pc_csp <- "RAS";
	float milkery_patch;
	

	/////////////////////////MAJ\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	float cmilk; // collected milk

	//est ce que une cell Pc est a une distance adequoite du troupeau
	bool link_neighbors <- false;

	// action calcul biomass par cellule
	float compute_biomass (int Mois, string current_season)
	{
		int abiomass <- 0;
		if (current_season = "bad")
		{
			abiomass <- bad_pic_biomass;
		}

		if (current_season = "medium")
		{
			abiomass <- medium_pic_biomass;
		}

		if (current_season = "good")
		{
			abiomass <- good_pic_biomass;
		}

		list<float> percentages <- biomass_percentages[Mois];
		abiomass <- int(abiomass * percentages[0]);
		return int(abiomass * (percentages[1] / 100));
	}

	action biomass_patch
	{
		
			biomass <- current_biomass * patch_surface;
		
	}

	//convertion kilometre en nombre de cellules et vis versa
	float km2patch_nb (int km)
	{
		return km * 460 / patch_length;
	}

	float patch_nb2km (int p_nb)
	{
		return p_nb * patch_length / 460;
	}

	//grass_surface <- grass_cnt * patch_surface;
	//rgb color <- rgb(248, 222, 126); //le fond est de coleur blanche
}

experiment main type: gui
{
//parametrage
	parameter 'percentage_small' var: percentage_small category: "Troupeau/Miniferme" min: 0 max: 100;
	parameter 'percentage_medium' var: percentage_medium category: "Troupeau/Miniferme" min: 0 max: 100;
	parameter 'percentage_large' var: percentage_large category: "Troupeau/Miniferme" min: 0 max: 100;
	parameter 'nombre de CSP' var: cspNumber category: "Troupeau/Miniferme" min: 0 max: 17;
	parameter 'crop_residue_price' var: crop_residue_price category: "parametres prix" min: 0 max: 100;
	parameter 'delivered_price' var: delivered_price category: "parametres prix" min: 0 max: 600;
	parameter 'collected_price' var: collected_price category: "parametres prix" min: 0 max: 600;
	parameter 'milking_percentage' var: milking_percentage category: "parametres MiniFerme" min: 0 max: 100;
	parameter 'small_probability' var: small_probability category: "parametres transhumance" min: 0 max: 100;
	parameter 'medium_probability' var: medium_probability category: "parametres transhumance" min: 0 max: 100;
	parameter 'large_probability' var: large_probability category: "parametres transhumance" min: 0 max: 100;
	parameter 'bad_pic_biomass' var: bad_pic_biomass category: "parametres ecologique" min: 0 max: 2000;
	parameter 'medium_pic_biomass' var: medium_pic_biomass category: "parametres ecologique" min: 0 max: 2000;
	parameter 'good_pic_biomass' var: good_pic_biomass category: "parametres ecologique" min: 0 max: 2000;
	parameter 'cow_ingestion_ratio' var: cow_ingestion_ratio category: "parametres Forage" min: 0 max: 100;
	parameter 'maximum_consumption' var: maximum_consumption category: "parametres Forage" min: 0.0 max: 1000.0;
	parameter 'complement_limit' var: complement_limit category: "parametres ecologique" min: 0 max: 500;
	parameter 'crop_residue_stock' var: crop_residue_stock category: "parametres Forage" min: 0.0 max: 5000.0;
	parameter 'starving_limit' var: starving_limit category: "parametres Forage" min: 0 max: 1000;
	parameter 'pasture_ci' var: pasture_ci category: "parametres carbone" min: -5.0 max: 5.0;
	parameter 'crop_residue_ci' var: crop_residue_ci category: "parametres carbone" min: -5.0 max: 5.0;
	parameter 'moto_ci' var: moto_ci category: "parametres carbone" min: -5.0 max: 5.0;
	parameter 'car_ci' var: car_ci category: "parametres carbone" min: -5.0 max: 5.0;
	parameter 'upkeep_ufl' var: upkeep_ufl category: "parametres lait" min: 0.0 max: 2.5;
	parameter 'small_consumption' var: small_consumption category: "parametres lait" min: 0 max: 10;
	parameter 'medium_consumption' var: medium_consumption category: "parametres lait" min: 0 max: 10;
	parameter 'large_consumption' var: large_consumption category: "parametres lait" min: 0 max: 10;
	parameter 'collect_radius' var: collect_radius category: "Troupeau/Miniferme" min: 0 max: 50;
	parameter 'water_radius' var: water_radius category: "parametres MiniFerme" min: 0 max: 50;
	parameter 'residue_radius' var: residue_radius category: "parametres MiniFerme" min: 0 max: 50;
	parameter 'gridbiomass' var: gridbiomass category: "gridbiomass";
	output
	{
		display CarteVectorial type:opengl
		{
			grid cell1 lines: rgb('black') triangulation: true refresh: false ;
			
			species PluvialShape refresh: false;
			species mareCadreShape refresh: false;
			//species HydroShape;
			species Hydro1Shape;
			species IrrigueShape;
			species forage_selShape refresh: false;
			species FerloShape refresh: false;
			species AgroIShape refresh: false;
			species Routes_pistesShape refresh: false;
			species Routes_pistesShape2 refresh: false;
			species CircuitsShape refresh: false;
			species centreShape refresh: false;
			species PointRencontreShape refresh: false;
			species cspShape refresh: false;
			//species init_climate;
		}

		display HowToImportVectorialgrille type:opengl
		{
			grid cell lines: rgb('black') triangulation: true refresh: false;
			species Troupeau aspect: image ;
			species PointRencontreShape refresh: false;
		}
		//afficher les grahes

		//afficher les grahes
		display biomasse_lait refresh: every(1 # cycle)
		{
			chart "Pasture biomass/head" type: series size: { 1, 0.5 } position: { 0, 0 }
			{
				data "biomasse pastorale" value: ((Cellbiomass) sum_of (each.biomass) / cow_nb) * (cow_ingestion_ratio / 100) style: line color: # black;
				data "starving-limit" value: starving_limit style: line color: # red;
				data "complement-limit" value: complement_limit style: line color: # green;
			}
			//graphe lait produit par troupeau
			chart "Milk production / head" type: series size: { 1, 0.5 } position: { 0, 0.5 } 
			{
				data "Troupeau" value: int((Troupeau where (each.htype != "minifarm" and each.milking_nb != 0)) sum_of (int(each.milk / each.milking_nb)) / length((Troupeau) where	(each.htype != "minifarm"))) style: line color: # black;
				data "Mini ferme" value: int((Troupeau where (each.htype = "minifarm")) sum_of (int(each.milk / each.milking_nb)) / length((Troupeau) where (each.htype = "minifarm"))) style:line color: # red;
			}

		}

		display impact_carbone refresh: every(1 # cycle)
		{
		//impact carbone
			chart "Carbon balance" type: series size: { 1, 0.5 } position: { 0, 0.0 }
			{
				data "balace carbone" value: int(carbon_impact) style: line color: # black;
			}

		}

		display distribution refresh: every(1 # cycle)
		{
		//impact carbone
			chart "Milk distribution" type: series size: { 1, 0.5 } position: { 0, 0.0 }
			{
				data "market-milk" value: market_milk style: line color: # black;
				data "consumed" value: (Troupeau) sum_of (each.consumed) style: line color: # red;
				data "cmilk" value: int((CellPc) sum_of (each.cmilk)) style: line color: # green;
			}

			chart "cow density" type: series size: { 1, 0.5 } position: { 0, 0.5 }
			{
				data "cow density" value: cow_nb / grass_surface style: line color: # black;
			}

		}

		display biomass_to_produce_milk refresh: every(1 # cycle)
		{
		//pour eviter l'erreur qui apparait dans netlogo nous n'effectuons pas les calculs ici
			chart "biomass to produce milk" type: series size: { 1, 0.5 } position: { 0, 0.0 }
			{
				data "biomass to produce milk" value: biotp style: line color: # black;
			}

			chart "Average revenue" type: series size: { 1, 0.5 } position: { 0, 0.5 }
			{
				data "incomT" value: (Troupeau where (each.htype != "minifarm") sum_of (each.income)) / length(Troupeau where (each.htype != "minifarm")) style: line color: # black;
				data "incomF" value: (Troupeau where (each.htype = "minifarm") sum_of (each.income)) / length(Troupeau where (each.htype = "minifarm")) style: line color: # red;
			}

		}

		//affiche les ecran 
		//deja dans l'on peut afficher des ecran sur les variables sans le mettre en place soit même
		monitor "mois" value: months[nbMois];
		monitor "season" value: season;
		monitor "laitiere" value: (Troupeau where (each.pcTrouve=true)) sum_of (each.milking_nb);
		monitor "cows" value: cow_nb;
	}

}
