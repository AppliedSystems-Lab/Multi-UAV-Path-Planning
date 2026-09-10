# Multiple UAV Path Planning

This project is being developed as part of the **MATLAB and Simulink Challenge Project Hub**.

The objective is to explore autonomous UAV navigation in urban environments, including 3D mapping, collision free path planning, multiple UAV coordination, and task allocation.

[View the official MathWorks challenge](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/tree/main/projects/Multi-UAV%20Path%20Planning%20for%20Urban%20Air%20Mobility)





 ![Budapest urban OSM](Results/figures/Budapest_urban_scenario.png) 
 **Budapest urban OSM**  

### GNSS

| ![GNSS satellite visibility and multipath simulation in Budapest](Results/figures/GNSS_Bud.png) |
|:--:|
| **GNSS satellite LOS and multipath reception in the scenario.** |

### Single UAV Mission
| ![Pathing in single mission UAV](Results/figures/Single_UAV_mission.png) |
|:--:|
| **A simple mission in scenario.** |


### UAV Delivery Mission

| ![Budapest UAV delivery mission](Results/figures/budapest_single_mission.gif) |
|:--:|
| **Takeoff, waypoint navigation, delivery hover, return, and landing mission.** |

### LiDAR Mapping

A UAV performs an aerial survey of the environment using simulated LiDAR.  
The collected point clouds are used to construct a 3D occupancy map of the surrounding terrain and buildings.

| ![LiDAR occupancy map](Results/figures/LIDAR_Occupancy_Map.png) |
|:--:|
| **3D occupancy map generated from UAV LiDAR measurements.** |

### Autonomous Path Planning with RRT*

The generated occupancy map is inflated to introduce an obstacle safety margin and is then used by an RRT* planner to generate a collision free 3D route between a start and goal position.

| ![RRT occupancy map](Results/figures/RRT_Occupancy_Map.png) |
|:--:|
| **Collision free RRT* path generated through the LiDAR derived occupancy map.** |

### Autonomous UAV Flight

The RRT* path is converted into a UAV trajectory and executed by the same UAV inside the scenario.

| ![RRT UAV flight](Results/figures/RRT_UAV_Flight.png) |
|:--:|
| **UAV executing the automatically generated RRT* trajectory.** |

### RRT Path planning for two UAVs
In the Multi_UAV_Planner file, we used the previous script of the RRT* algorithm and plotted a second UAV using the same algorithm.
| ![Two UAV Paths](Results/figures/TwoUAVs_RRT.png) |
|:--:|
| **Two UAVs with colliding/intersecting RRT* paths** |

Also, for this section I tried to plot the separation graph between two assumed UAVs, so later on we can add a threshold of minimum separation difference so we can predict where the UAVs may collide depending on there path(Useful when the airspace is saturated)
|![Separation Graph for two UAVs](Results/figures/Separation_Graph_two_UAVs.png) |
|:--:|
|**You can probably tell the distance is reducing between these two**|