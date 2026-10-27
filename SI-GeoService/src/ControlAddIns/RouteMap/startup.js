(function () {
    var root = document.getElementById('controlAddIn');
    if (!root) { throw new Error('SI Geo Route Map: controlAddIn container missing'); }
    root.innerHTML = '<div id="si-geo-map"><div id="si-geo-tiles"></div><svg id="si-geo-overlay" xmlns="http://www.w3.org/2000/svg"><path id="si-geo-route"/><circle id="si-geo-start" r="7"/><circle id="si-geo-end" r="7"/></svg><div class="si-geo-controls"><button id="si-geo-plus" type="button" title="Наблизити">+</button><button id="si-geo-minus" type="button" title="Віддалити">−</button><button id="si-geo-fit" type="button" title="Увесь маршрут">⌖</button></div><div class="si-geo-label">Маршрут Geoapify · підкладка © OpenStreetMap</div><div id="si-geo-notice">Розрахуйте маршрут і натисніть «Показати маршрут»</div></div>';
    window.siGeoRouteMapInit();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
})();
