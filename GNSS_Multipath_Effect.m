scene = Create_Scenario_Cuboid()
uavTrajectory = waypointTrajectory([-272.205,-95.8848,200; 141.63,-95.8897,200],TimeOfArrival=[0 scene.StopTime],ReferenceFrame="ENU");
referenceLocation = scene.ReferenceLocation;


plat = uavPlatform("UAV",scene,Trajectory=uavTrajectory,ReferenceFrame="ENU");
updateMesh(plat,"quadrotor",{1},[1 0 0], eye(4));
gnss = uavSensor("GNSS",plat,gnssMeasurementGenerator(ReferenceLocation=referenceLocation));
fig = figure;
ax = show3D(scene);
uavPostion = uavTrajectory.lookupPose(linspace(0,scene.StopTime,100));
hold on
uavTrajectoryLine = plot3(uavPostion(:,1),uavPostion(:,2),uavPostion(:,3),"--",LineWidth=1.5,Color="cyan");
legend(uavTrajectoryLine,"Trajectory",Location="North East")

helperUpdateScenarioView(ax);


clf(fig,"reset")
set(fig,Position=[400 458 1120 420])

hScenePlot = uipanel(fig,Position=[0 0 0.5 1]);
ax = axes(hScenePlot);
[~,pltFrames] = show3D(scene,Parent=ax);
hold(ax,"on")
uavMarker = plot(pltFrames.UAV.BodyFrame,0,0,Marker="o",MarkerFaceColor="cyan");
uavTrajectoryLine = plot3(uavPostion(:,1),uavPostion(:,2),uavPostion(:,3),"--",LineWidth=1.5,Color="cyan");
legend(ax,[uavMarker uavTrajectoryLine],["UAV","Trajectory"],Location="northeast")
view(ax,[0 90])
axis(ax,"equal")
hold(ax,"off")
hSkyPlot = uipanel(fig,Position=[0.5 0 0.5 1]);
sp = skyplot(NaN,NaN,Parent=hSkyPlot);
title("GPS Satellites with LOS and Multipath Reception")
legend(sp)
colors = colororder(sp);
colororder(sp,[0.6*[1 1 1]; colors(7,:); colors(5,:)])

currTime = gnss.SensorModel.InitialTime;
setup(scene)
while scene.IsRunning
    % Read the satellite pseudoranges.
    [~,~,p,satPos,status] = gnss.read();
    allSatPos = gnssconstellation(currTime);
    currTime = currTime + seconds(1/scene.UpdateRate);

    % Get the satellite azimuths and elevations from satellite positions.
    [~,trueRecPos] = plat.read;
    [az,el] = lookangles(trueRecPos,satPos,gnss.SensorModel.MaskAngle);
    [allAz,allEl,vis] = lookangles(trueRecPos,allSatPos,gnss.SensorModel.MaskAngle);
    allEl(allEl<0) = NaN;

    % Set categories of satellites based on the status (Blocked, Multipath, or Visible).
    groups = categorical([-ones(size(allAz)); status.LOS],[-1 0 1],["Blocked","Multipath","Visible"]); 

    % Set different marker sizes so that you can see the multiple measurements from the same satellite. 
    markerSizes = 100*ones(size(groups));
    markerSizes(groups=="Multipath") = 150;

    % Update the sky plot.
    set(sp,AzimuthData=[allAz; az],ElevationData=[allEl; el],GroupData=groups,MarkerSizeData=markerSizes);
    show3D(scene,Parent=ax,FastUpdate=true);
    drawnow

    % Advance the scene simulation time and update all sensor readings.
    advance(scene);
    updateSensors(scene)

end