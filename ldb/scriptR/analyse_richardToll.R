# Date : 27 avril 2021
# Lieu : Richard Toll

library(ggplot2)

setwd("github/ldb_sng/ldb/")
source("scriptR/multiplot_function.R")


## PLot l'influence de la stochastisité
df <- read.csv("results/simulation_replication.csv", sep = ",", header = T)

sel <- df$cycle == 25
sdf <- df[sel,]


v <- seq(from= 5, to = 50, by = 5)

sample_function <- function(data.df, vect){
  data <- data.frame()
  for(i in 1:length(vect)){
    a <- data.frame(value = sample(data.df$producedMilk, vect[i]), sample = rep(vect[i], length(vect[i])))
    data <- rbind(data, a)
  }
  return(data)
}

r <- sample_function(sdf, v)

ggplot(data = r)+
  geom_boxplot(aes(x = factor(sample), y = value))



## PLot l'influence du nombre de CSP sur le nombre de tête de bétails qui
names(simu)
simu <- read.csv("results/simulation_csp.csv")
nbtete <- ggplot(data = simu, aes(x = cspNumber, y = nbheard_in_csp))+
  geom_point()+
  geom_smooth()+
  labs(x = "Nombre de Centres de Service de Proximité", y = "Nombre de têtes de bétail couvertes", title = "5 réplications des simulations")+
  theme_bw()

ggsave("img/betail_couvert_csp.png", width = 8)

# biomass c'est la matière sèche = résidut et biomass pasto.
# La biomass réduit parce qu'il à des départ en tranhumance
# et jusqu'a 50 CSP. A près il y a moins de départ et donc 
# + de biomass est utilisé
biomassTete <- ggplot(data = simu, aes(x = cspNumber, y = biomassHead))+ 
  geom_point()+
  geom_smooth()+
  labs(x = "Nombre de Centres de Service de Proximité", y = "biomasse par têtes", title = "5 réplications des simulations")+
  theme_bw()

multiplot(nbtete, biomassTete)

## Petite exploration 
## Simulation du 25 avril 
## 1 réplication 
## Variations de : 
### nb_minifarms <- c(0, 50,100)
### cspNumber <- c(0,50, 100)
### crop_residue_price <- seq(from=20, to=100, by=20)
### delivered_price <- c(200, 400, 600)
### collected_price <- c(200, 400, 600)

explo <- read.csv("results/simulation.csv")

