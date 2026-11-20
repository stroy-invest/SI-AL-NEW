window.RenderTree = function(treeJson) { window.siVehicleTreeRender(treeJson); };
window.RenderCharacteristics = function(json) { window.siVehicleCharacteristicsRender(json); };
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
