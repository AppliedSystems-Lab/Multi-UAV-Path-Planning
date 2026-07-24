scene = Create_Scenario_Cuboid();
waypoints = [-81.1517, 109.077, 300;
             -69.8244, -79.9673, 250;
             336.47, -184.503, 300;
             327.181, 74.75, 300;
             -81.1517, 109.077, 300];
toa = [0 5 10 15 20];
trajectory = waypointTrajectory(waypoints, TimeOfArrival=toa,SampleRate=1);
uav = uavPlatform("Alpha1",scene,Trajectory=trajectory);
updateMesh(uav,"quadrotor",{40},[1 0 0],eul2tform([0 0 pi]));

fig_axis = show3D(scene);
hold(fig_axis,"on");
plot3(fig_axis,waypoints(:,1),waypoints(:,2),waypoints(:,3),"-o");
hold(fig_axis,"off");
setup(scene)
while advance(scene)
    show3D(scene,Parent=fig_axis,FastUpdate=true);
    drawnow limitrate;
end