scene = Create_Scenario_Cuboid();
waypoints = [309.281, 323.134, 200;
             144.586, 290.189, 200;
             156.379, 192.483, 200;
             321.443, 213.848, 200;
             309.281, 323.134, 200];
toa = [0 5 10 15 20];
trajectory = waypointTrajectory(waypoints, TimeOfArrival=toa,SampleRate=1);
uav = uavPlatform("Alpha1",scene,Trajectory=trajectory);
updateMesh(uav,"quadrotor",{10},[1 0 0],eul2tform([0 0 pi]));

fig_axis = show3D(scene);
hold(fig_axis,"on");
plot3(fig_axis,waypoints(:,1),waypoints(:,2),waypoints(:,3),"-o");
hold(fig_axis,"off");