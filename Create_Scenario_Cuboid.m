function scene = Create_Scenario_Cuboid()
scene = uavScenario(UpdateRate=10,StopTime=100,ReferenceLocation=[47.50711856431289, 19.047039706097962 0]);
xlimits = [-400 400];
ylimits = [-400 400];
color = [0.6 0.6 0.6];
terrainInfo = addMesh(scene,"terrain",{"gmted2010",xlimits,ylimits},color,Verbose=true);
xbuilding_limit = [-400 400];
ybuilding_limit = [-400 400];
color = [0.6431 0.8706 0.6275];
osmInfo = addMesh(scene,"buildings",{'Geo_data/budapest.osm',xbuilding_limit,ybuilding_limit,"auto"},color,Verbose=true);
%show3D(scene);

end