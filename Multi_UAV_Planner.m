clear;
clc;
close all;
%set the env
simTime = 135;
scene = uavScenario(ReferenceLocation=[47.507014314851375, 19.04718380067424 0], ...
    UpdateRate=2,StopTime=simTime);
xTerrainLimits = [-200 200];
yTerrainLimits = [-200 200];
addMesh(scene,"terrain",{'gmted2010',xTerrainLimits,yTerrainLimits},[0.6,0.6,0.6]);
xBuildingLimits = [-150 150];
yBuildingLimits = [-150 150];
addMesh(scene,"buildings",{"Geo_data/budapest.osm",xBuildingLimits,yBuildingLimits,"auto"},[0.6431,0.8706,0.6275]);
groundHeight = terrainHeight(scene,0,0);
fprintf("Ground H: %.2f m \n",groundHeight);


%map the fl
mappingAltitude = groundHeight + 70;
mappingWaypoints = [
    -120 -120 mappingAltitude
    120 -120 mappingAltitude
    120 -60 mappingAltitude
    -120 -60 mappingAltitude
    -120 0 mappingAltitude
    120 0 mappingAltitude
    120 60 mappingAltitude
    -120 60 mappingAltitude
    -120 120 mappingAltitude
    120 120 mappingAltitude
    ];
mappingTime = 0 : 15 : 135;

%traj
orientation = quaternion([0 0 0],"eulerd","ZYX","frame");
orientations = repmat(orientation,10,1);
mappingTrajectory = waypointTrajectory( ...
    "Waypoints",mappingWaypoints, ...
    "Orientation",orientations, ...
    "TimeOfArrival",mappingTime, ...
    "SampleRate",2, ...
    "ReferenceFrame","ENU");
%uav
mappingUAV = uavPlatform( ...
    "MappingUAV", ...
    scene, ...
    "Trajectory",mappingTrajectory, ...
    "ReferenceFrame","ENU");

updateMesh( ...
    mappingUAV, ...
    "quadrotor", ...
    {8}, ...
    [1 0 0], ...
    eye(4));
%% Add LiDAR

lidarModel = uavLidarPointCloudGenerator( ...
    "AzimuthResolution",0.6, ...
    "ElevationLimits",[-90 -20], ...
    "ElevationResolution",2.5, ...
    "MaxRange",200, ...
    "UpdateRate",2, ...
    "HasOrganizedOutput",true);

lidar = uavSensor( ...
    "Lidar", ...
    mappingUAV, ...
    lidarModel, ...
    "MountingLocation",[0 0 -1], ...
    "MountingAngles",[0 0 0]);

%% Create empty 3D occupancy map

map3D = occupancyMap3D(1);
figure;

[ax,plotFrames] = show3D(scene);

xlim(ax,[-200 200]);
ylim(ax,[-200 200]);
zlim(ax,[140 250]);

view(ax,[-45 30]);
axis(ax,"equal");

setup(scene);

while scene.IsRunning

    % Read latest LiDAR scan
    [isUpdated,lidarTime,ptCloud] = read(lidar);

    if isUpdated

        % Get LiDAR pose in the ENU world frame
        sensorPose = getTransform( ...
            scene.TransformTree, ...
            "ENU", ...
            "MappingUAV/Lidar", ...
            lidarTime);

        % Remove invalid LiDAR points
        validCloud = removeInvalidPoints(ptCloud);

        % Add scan to occupancy map
        insertPointCloud( ...
            map3D, ...
            [sensorPose(1:3,4)' tform2quat(sensorPose)], ...
            validCloud, ...
            500);
    end

    % Advance UAV
    advance(scene);

    % Generate new sensor data
    updateSensors(scene);

end
%% Show generated occupancy map

inflate(map3D,3);
figure;

show(map3D);

axis equal;
view([-45 30]);

title("3D Occupancy Map");
%% RRT* path planning

ss = stateSpaceSE3([
    -180 180
    -180 180
    groundHeight+10 groundHeight+80
    inf inf
    inf inf
    inf inf
    inf inf
    ]);

sv = validatorOccupancyMap3D( ...
    ss, ...
    Map=map3D, ...
    ValidationDistance=0.5);
planner = plannerRRTStar( ...
    ss, ...
    sv, ...
    MaxConnectionDistance=60, ...
    MaxIterations=3000, ...
    GoalReachedFcn=@(~,s,g)(norm(s(1:3)-g(1:3)) < 3), ...
    GoalBias=0.1);
% UAVs start and goal pos
% UAV1: SW -> NE
start1 = [-80 -80 groundHeight+40 1 0 0 0];
goal1 = [100 80 groundHeight+40 1 0 0 0];
% UAV2: SE -> NW
start2 = [100 -80 groundHeight+40 1 0 0 0];
goal2 = [-80 80 groundHeight+40 1 0 0 0];
%% Check start and goal for both Uavs

start1Valid = isStateValid(sv,start1)
goal1Valid = isStateValid(sv,goal1)

start2Valid = isStateValid(sv,start2)
goal2Valid = isStateValid(sv, goal2)

%% Plan collision-free path ???



%Uav - 1
rng(1,"twister");
[pathUAV1,infoUAV1] = plan(planner,start1,goal1);

%Uav - 2
rng(2,"twister")
[pathUAV2,infoUAV2] = plan(planner,start2,goal2);

%% Show both planned paths

figure;

show(map3D);
axis equal;
view([-45 30]);
hold on;

% UAV 1 path
plot3( ...
    pathUAV1.States(:,1), ...
    pathUAV1.States(:,2), ...
    pathUAV1.States(:,3), ...
    LineWidth=3);

% UAV 2 path
plot3( ...
    pathUAV2.States(:,1), ...
    pathUAV2.States(:,2), ...
    pathUAV2.States(:,3), ...
    LineWidth=3);

% UAV 1 start / goal
scatter3(start1(1),start1(2),start1(3),80,"filled");
scatter3(goal1(1),goal1(2),goal1(3),80,"filled");

% UAV 2 start / goal
scatter3(start2(1),start2(2),start2(3),80,"filled");
scatter3(goal2(1),goal2(2),goal2(3),80,"filled");

title("Two-UAV RRT* Path Planning");

legend( ...
    "UAV 1 Path", ...
    "UAV 2 Path", ...
    "UAV 1 Start", ...
    "UAV 1 Goal", ...
    "UAV 2 Start", ...
    "UAV 2 Goal");

hold off;

%% Check separation between UAVs

cruiseSpeed = 8;   % m/s

% Extract RRT* XYZ waypoints
waypoints1 = pathUAV1.States(:,1:3);
waypoints2 = pathUAV2.States(:,1:3);

%% Calculate timing for UAV 1

distances1 = vecnorm(diff(waypoints1),2,2);
times1 = distances1 / cruiseSpeed;
arrivalTimes1 = [0; cumsum(times1)];

%% Calculate timing for UAV 2

distances2 = vecnorm(diff(waypoints2),2,2);
times2 = distances2 / cruiseSpeed;
arrivalTimes2 = [0; cumsum(times2)];

fprintf("UAV 1 flight time: %.2f s\n",arrivalTimes1(end));
fprintf("UAV 2 flight time: %.2f s\n",arrivalTimes2(end));

%% Create timed UAV trajectories

trajectory1 = waypointTrajectory( ...
    Waypoints=waypoints1, ...
    TimeOfArrival=arrivalTimes1, ...
    SampleRate=2, ...
    ReferenceFrame="ENU");

trajectory2 = waypointTrajectory( ...
    Waypoints=waypoints2, ...
    TimeOfArrival=arrivalTimes2, ...
    SampleRate=2, ...
    ReferenceFrame="ENU");

%% Inter-UAV separation analysis

dt = 0.5;

totalTime = max(arrivalTimes1(end),arrivalTimes2(end));
timeVector = 0:dt:totalTime;

separation = zeros(size(timeVector));

for k = 1:length(timeVector)

    t = timeVector(k);

    % UAV 1 position
    if t <= arrivalTimes1(end)
        position1 = lookupPose(trajectory1,t);
    else
        position1 = waypoints1(end,:);
    end

    % UAV 2 position
    if t <= arrivalTimes2(end)
        position2 = lookupPose(trajectory2,t);
    else
        position2 = waypoints2(end,:);
    end

    separation(k) = norm(position1 - position2);
end

%% Minimum separation

[minSeparation,minIndex] = min(separation);
minTime = timeVector(minIndex);

fprintf("Minimum UAV separation: %.2f m\n",minSeparation);
fprintf("Closest approach time: %.2f s\n",minTime);

figure;

plot(timeVector,separation,LineWidth=2);
grid on;

xlabel("Time (s)");
ylabel("UAV Separation (m)");
title("UAV Separation");