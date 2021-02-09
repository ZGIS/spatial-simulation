# ABM for Socio-Economic Monitoring of Visitor Streams in Harz NP

## Main goals
Due to the large extent of the Harz National Park, an accurate measurement of visitor numbers and their spatiotemporal distribution is not feasible. This model demonstrates the possibility to simulate the streams of visitors with ABM methodology.

The goal of this model is to simulate groups of hikers in the study area around the Brocken, in the Harz NP. As a result, national park management will be provided with key figures (e.g. numbers of visitors to POIs, of hikers on paths) for socio-economic monitoring.

## Programming language
This agent-based model (ABM) is written in GAMA. To run this code you need GAMA 1.7 or higher. Futher information is available here: https://gama-platform.github.io/

## File structure
### Directory include
Includes all necessary data (e.g. shapefiles).

### Directory models
Main program directory. There is only one file `Harz National Park Hikers.gaml` with all subroutines together.

### Directory tests
Several tests and code snippets which have been used during the development of this ABM.

### Directory output
Simulation generated output of the results from the ABM will be placed here. Actually there are no files in here, because you havent't run any simulation now.

### Directory figures
Contains some figures for these README files and explanations. You don't need it for sunning the simulation code.

## Other sources for this code
The code of the model has also been published at the CoMSES / OpenABM network: https://www.comses.net/codebases/6014/releases/1.0.0/

## Introduction
The Harz National Park offers with 813 km a well-developed path network as well as a high number of starting and destination points (POIs) for hikes, and was visited by some 1.7 million visitors in 2014. Due to its large extent, an accurate measurement of visitor numbers and their spatiotemporal distribution is not feasible. This work demonstrates the possibility to simulate the streams of visitors around Mt. Brocken with the agent-based model (ABM) methodology. The GAMA v1.7 RC2 modelling environment was chosen, because it has very extensive spatial operators and simulation tasks, combined with an easy-to-understand modelling language. To reduce the simulation effort, a model reduction factor MRF = 10 was tested successfully and used without any significant change to the model. After an initial parameterization, a sensitivity analysis was conducted with the results included in the final calibration. The observed error value could be significantly reduced from RMSE_Param=0,3817 to RMSE_Kalib=0,1069 and therefore the model was successfully adapted to the study area. For the final validation visitor numbers from other, independent investigations were used. Besides the identified 12 main routes and 7 hotspots not only basic socioeconomic indicators were provided, but also the change of behaviour of hikers following a variation of framework conditions was analyzed, thus demonstrating the impact of currently implemented measures to reduce path density. The final result is a flexible and expandable baseline model, which provides a realistic picture of the spatial distribution of hikers in the study area and additional socioeconomic key figures.

![Study area for the ABM](https://github.com/nordie69/ABM-for-Socio-Economic-Monitoring-of-Visitor-Streams-in-Harz-NP/blob/main/figures/Fig3_Study_area.jpg "Study area for the ABM")

*Figure 1: Study area Harz National Park for this ABM*


# Short ODD protocol for the model
The description of the model is in a shortened form, according to the updated version of the Overview, Design concepts and Details (ODD) protocol (Grimm et al., 2010a, 2010b).

## Purpose
The goal of this model is to simulate groups of hikers in the study area around the Brocken, in the Harz NP. As a result, national park management will be provided with key figures (e.g. numbers of visitors to POIs, of hikers on paths) for socio-economic monitoring.

## Entities, state variables and scales
The data for the structure of the study area is in the form of shapefiles. The study area has an extent of approximately 17,850 m (N-S) x 14,650 m (E-W). All data in the shapefiles is in metres (m); velocities are given in metres per second (m / s). Numbers are given in units, and proportional values as percentages (%). One cycle in the model corresponds to 300 s real time; the simulated time period per day is 07:00 to 19:00. The length of a year is assumed to be 365 days. In the model, 14 entities are used as agents, 2 of which serve purely for representation (main roads and railway lines), 4 are designed to determine measured values (fishnet for the heat map, count points, count polygons, total count area), 1 for both counting and representing an entity, 1 represents the hikers’ route network (path network), 5 serve as start and finish points (carparks, bus stops, towns, train stations and POIs), and 1 represents the groups of hikers in the model. The model uses a global reduction factor (MRF = 10), which reduces the number of hiker-agents to be simulated. The factor was chosen so that there would be no noticeable influence on model results. A check of the exponentially increasing runtime of the model results in a value of tMRF,10 = 8.076 ± 668 s for MRF ≥ 10.

## Process overview and scheduling
The structure of the model is shown in Figure 2. It is divided into the main areas of initialization, daily cycle[run?] and completion. The daily run is repeated until the desired simulation year has ended.

![Flowchart of the model](https://github.com/nordie69/ABM-for-Socio-Economic-Monitoring-of-Visitor-Streams-in-Harz-NP/blob/main/figures/Fig4_Flowchart.jpg "Flowchart of the model") 

*Figure 2: Flowchart of the model*

## Basic principles
Figure 3 shows an Entity Relationship Diagram (ERD) to illustrate the relationships between the individual entities. Some entities serve the same purpose, so they can be grouped into scopes.

![ERD illustrating the relationships between the entities](https://github.com/nordie69/ABM-for-Socio-Economic-Monitoring-of-Visitor-Streams-in-Harz-NP/blob/main/figures/Fig5_ERD.jpg "ERD illustrating the relationships between the entities") 
 
*Figure 3: ERD illustrating the relationships between the entities*

## Emergence
The spatio-temporal distribution of the groups of hikers in the study area represents the essential emergent variable of the model. This determines the usage of the paths and the number of visitors encountered at the POIs and cannot be determined beforehand. The distribution of nature-oriented hikers is not determined deterministically, due to how they select paths.

## Adaption
Parking is limited by the capacity of the carparks located in the study area. Since in most cases several carparks are located near a starting point, the groups of hikers arriving by car select from the available carparks and thus already deviate from these starting points when choosing their carpark. The weather also influences walking speed: in poor weather conditions, there is a stronger urge to reach the goals (POIs). In contrast, hikers may spend more time at the POIs in better weather conditions. Nature-oriented hikers perceive the prevailing conditions differently, preferring more natural paths and avoiding paths with higher numbers of hikers.

## Objectives
Hikers in the model follow several objectives, which are also reflected in the state changes described below (see Figure 4). First, every group of hikers has to find a starting point. Then it selects a main POI within its available distance budget, which is based on a normal distribution (x ̅=18 km) and is determined individually for each hiking group. On the way to their POI and back to the starting point, a number of secondary POIs are available, which can also be accessed as destinations. Return to the starting point before nightfall is also an objective, influencing the length of the route, and taking the start time and sunset into account.

## Prediction, Sensing, Stochasticity and Collectives
When adding POIs as additional targets, the hiker-agents estimate their actions using pre-set restrictions. No additional targets are added to the hike if the permissible length is exceeded or the return time would be after sunset. Hiker-agents take values from their environment and are influenced by them. These are
- weather conditions,
- number of hikers on trails,
- difficulty level of trails,
- category of trails (e.g. small paths, larger paths), and
- the state of the trail in winter.

The model contains a number of variables which exhibit a stochastic behaviour and for which a Gaussian normal distribution is assumed. Within the model, there is no dynamic grouping of agents. Implicitly, the merging of hikers into groups of hikers is such an approach.

## Observation
The simulation within the model include a map showing the location of all stationary entities, the current locations of the groups of hikers, and advanced dynamic information. The simulation is equipped with 10 graph groups, which provide insights into the development of individual values within the model at runtime. In addition, there are a number of value monitors available, with which the most important model results can be read. The 47 model outputs are grouped into
- general values,
- visitor numbers and shares, 
- visitor numbers for NP facilities, 
- visitor flows in the Brocken area, and 
- hikers who have also visited the Brocken ("Brockenhikers").

## Initialization
The number of groups of hikers is set at the beginning of a new day and is based on a so-called standard number, a random element, and various seasonal factors. The number of groups to be simulated per day is approximately 876 

`standard_number_of_groups = (mb_total_nlp_inside * k_12to24h)/(x_members_per_group * ∑k_season_i)*k_correction`

and is broken down as follows: car = 479, car stopover = 85, bus = 59, town = 32 units, and train station = 221 units.

## Input data
The total of 83 input variables with their starting values for the calibration of the basic model include:
- the model controlling parameters,; 
- the areas’ standard numbers and factors; 
- model representation and output; 
- number of groups of hikers; 
- environment, and 
- daily information.

Additional values are required to load shapefiles with fixed entities, to control the program flow, and to configure the GUI of the model. The day-dependent parameters are summarized as a CSV file and are loaded during the simulation run.

## Sub-models
Hikers can adopt 7 different statuses. The status transitions are defined as in Figure 4. This sub-model (or state engine) is used for each individual travelling group. The route selection in the model is carried out by means of a Dijkstra shortest-path algorithm, which reflects the hikers’ use of maps, handheld GPS and other mobile devices. The division of the overall model into additional sub-models is typical for a structured programming language.

![Sub-model of the state transitions of groups of hikers](https://github.com/nordie69/ABM-for-Socio-Economic-Monitoring-of-Visitor-Streams-in-Harz-NP/blob/main/figures/Fig6_State_diagram.jpg "Sub-model of the state transitions of groups of hikers") 
 
*Figure 4: Sub-model of the state transitions of groups of hikers*

# Example of results
For the whole study area, the annual sum of visitors is 1,515,464, with a concentration of 561,702 (about 37.1%) at the Brocken. 389,613 people (about 69.4%) travel using the Brocken Railway, and 172,089 (about 30.6%) hike to the Brocken. Thus, there is a spatial concentration of visitors in the area around the Brocken in the central part of the study area, which can be examined in more detail (see Figure 5). This concentration is primarily in the Scharf-enstein, Torfhaus, Schierke and Hohne areas. Noticeable in this context is the area to the east of the Brocken, which receives a comparatively small number of visitors. One of the main causes is the difficulty for hikers of finding a suitable starting point, as this eastern area is furthest away from points of entry to the National Park.

![Overall result of spatial distribution of hikers](https://github.com/nordie69/ABM-for-Socio-Economic-Monitoring-of-Visitor-Streams-in-Harz-NP/blob/main/figures/Fig7_Result_Overall_spatial_distribution.jpg "Overall result of spatial distrbution of hikers") 

*Figure 4: Example of results: Overall result of spatial distributi*on of hikers*