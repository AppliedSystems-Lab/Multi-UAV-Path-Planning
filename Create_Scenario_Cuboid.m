function scene = Create_Scenario_Cuboid()
scene = uavScenario(UpdateRate=1,StopTime=160,ReferenceLocation=[47.50711856431289, 19.047039706097962 0]);
xlimits = [-1100 1100];
ylimits = [-1100 1100];
color = [0.6 0.6 0.6];
terrainInfo = addMesh(scene,"terrain",{"gmted2010",xlimits,ylimits},color,Verbose=true);

color = [0 1 0];
osmInfo = addMesh(scene,"buildings",{'Geo_data/budapest.osm',xlimits,ylimits,"auto"},color,Verbose=true);
%show3D(scene);

end