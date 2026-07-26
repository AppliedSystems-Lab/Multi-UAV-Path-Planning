function helperUpdateScenarioView(ax)
% Update the scenario view in axes handle AX.
meshes = findobj(ax,"type","patch");
for idx = 1:numel(meshes)
    meshes(idx).LineStyle = "none";
end
light(ax,"Position",[1 -5 6])
view(ax,[0 40])
end