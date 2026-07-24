function scene = Create_Scenario_Cuboid()
scene = uavScenario(UpdateRate=1,StopTime=20,ReferenceLocation=[46.07600628194698, 18.207994868636025 0]);
xlimits = [-1100 1100];
ylimits = [-1100 1100];
color = [0.6 0.6 0.6];
terrainInfo = addMesh(scene,"terrain",{"gmted2010",xlimits,ylimits},color,Verbose=true);

color = [0 1 0];
osmInfo = addMesh(scene,"buildings",{'Geo_data/Pecs.osm',xlimits,ylimits,"auto"},color,Verbose=true);
%show3D(scene);

end