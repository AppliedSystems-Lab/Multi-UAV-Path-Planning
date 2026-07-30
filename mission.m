clear;
clc;
close all;
scene = uavScenario(ReferenceLocation=[47.507014314851375, 19.04718380067424 0],UpdateRate=5);
xTerrainLimits = [-200 200];
yTerrainLimits = [-200 200];
color = [0.6 0.6 0.6];
addMesh(scene,"terrain",{"gmted2010",xTerrainLimits,yTerrainLimits},color)
xBuildingLimits = [-150 150];
yBuildingLimits = [-150 150];
color = [0.6431 0.8706 0.6275];
addMesh(scene,"buildings",{"Geo_data/budapest.osm",xBuildingLimits,yBuildingLimits,"auto"},color)
groundHeight = terrainHeight(scene,0,0);

fprintf("Ground height at mission origin: %.2f m\n",groundHeight);

homeLocation = [ ...
    scene.ReferenceLocation(1), ...
    scene.ReferenceLocation(2), ...
    groundHeight];
figure;

routeAx = show3D(scene);

% Look directly down at Budapest
view(routeAx,[0 90]);
axis(routeAx,"equal");
grid(routeAx,"on");

title(routeAx, ...
    ["Click four safe points in order:" ...
    " WP1, WP2, WP3, Delivery"]);

disp("Click four points in open grey areas.");
disp("Do not click on green buildings.");

% Select four East-North positions
[eastPoints,northPoints] = ginput(4);

routeXY = [eastPoints northPoints];

disp("Selected East-North coordinates:");
disp(routeXY);
%% Calculate waypoint altitudes

% Height above the local terrain
flightClearance = 35;

% Absolute terrain heights at selected coordinates
routeGroundHeights = terrainHeight( ...
    scene, ...
    routeXY(:,1), ...
    routeXY(:,2));

% Convert absolute terrain altitude into Local ENU altitude
routeZ = routeGroundHeights ...
    - groundHeight ...
    + flightClearance;

waypointsENU = [routeXY routeZ];

disp("Complete Local ENU waypoints:");
disp(waypointsENU);
plat = uavPlatform("UAV",scene);
updateMesh(plat,"quadrotor",{3},[1 0 0],eul2tform([0 0 pi]));

m = uavMission( ...
    Frame="LocalENU", ...
    HomeLocation=homeLocation, ...
    Speed=8);

% Vertical takeoff to cruising clearance
addTakeoff(m,flightClearance,Pitch=15,Yaw=0);

% Outbound route
addWaypoint(m,waypointsENU(1,:),AcceptanceRadius=2);
addWaypoint(m,waypointsENU(2,:),AcceptanceRadius=2);
addWaypoint(m,waypointsENU(3,:),AcceptanceRadius=2);

% Delivery position
addWaypoint(m,waypointsENU(4,:),AcceptanceRadius=2);

% Hover for 15 seconds at the delivery location
addHover(m,waypointsENU(4,:),10,15);

% Return through the same safe corridor
addWaypoint(m,waypointsENU(3,:),AcceptanceRadius=2);
addWaypoint(m,waypointsENU(2,:),AcceptanceRadius=2);
addWaypoint(m,waypointsENU(1,:),AcceptanceRadius=2);

% Return home and land
addWaypoint(m,[0 0 flightClearance],AcceptanceRadius=2);
addLand(m,[0 0 0],Yaw=0);

showdetails(m);

% = uavMission( ...
%    Frame="LocalENU", ...
%    HomeLocation=homeLocation, ...
%    Speed=5);
% addTakeoff(m,20)
% addWaypoint(m,[10 0 30]);
% addChangeSpeed(m,20)
% addWaypoint(m,[20 0 40]);
% addChangeSpeed(m,5)
% addWaypoint(m,[30 0 50]);

%addLoiter(m,[40 0 60],10,20);
%addHover(m,[50 0 70],10,20);

%addLand(m,[70 0 0],Yaw=0);
%showdetails(m)
%show(m)
%axis equal
figure 
show3D(scene);
hold on
ax = show(m, ReferenceLocation=scene.ReferenceLocation);
missionLine = findobj(ax,"type","line");
missionText = findobj(ax,"type","text");

for idx = 1:numel(missionLine)
    missionLine(idx).LineWidth = 2;
end
for idx = 1:numel(missionText)
    p = missionText(idx).Position;
    missionText(idx).Position = p+[0 10 0];
    missionText(idx).HorizontalAlignment = "center";
    missionText(idx).VerticalAlignment = "bottom";
    missionText(idx).Margin = 1;
    missionText(idx).BackgroundColor = [1 1 1];
end
view(ax,[35 30])
axis(ax,"equal")
hold off
parser = multirotorMissionParser( ...
    TransitionRadius=2, ...
    TakeoffSpeed=2);

traj = parse(parser,m,scene.ReferenceLocation);

fprintf("Mission duration: %.2f seconds\n",traj.EndTime);
figure

ax = show3D(scene);
light(ax,Position=[-300 -300 300]);
view(ax,[35 30]);
axis(ax,"equal");

hold(ax,"on");

show(m,ReferenceLocation=scene.ReferenceLocation);
show(traj,NumSamples=200);

title(ax,"Budapest UAV Mission Simulation");

camzoom(ax,4);

%% Simulate UAV movement

setup(scene);

while scene.CurrentTime <= traj.EndTime

    % Get the UAV state at the current simulation time
    motion = query(traj,scene.CurrentTime);

    % Move the quadrotor
    move(plat,motion);

    % Refresh the Budapest environment
    show3D(scene,Parent=ax,FastUpdate=true);

    % Track the UAV with the camera
    nedPosition = motion(1:3);

    camtarget(ax,[ ...
        nedPosition(2), ...
        nedPosition(1), ...
        -nedPosition(3)]);

    % Advance simulation by one timestep
    advance(scene);

    drawnow limitrate
end

hold(ax,"off");