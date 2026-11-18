(function () {
    "use strict";
    const root = document.createElement("div");
    root.id = "si-iw-capacity-root";
    document.body.replaceChildren(root);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
})();
