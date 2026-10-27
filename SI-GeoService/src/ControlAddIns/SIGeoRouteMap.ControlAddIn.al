controladdin "SI Geo Route Map"
{
    RequestedHeight = 460;
    MinimumHeight = 320;
    MaximumHeight = 800;
    HorizontalStretch = true;
    VerticalStretch = true;
    Scripts = 'src/ControlAddIns/RouteMap/map.js';
    StartupScript = 'src/ControlAddIns/RouteMap/startup.js';
    StyleSheets = 'src/ControlAddIns/RouteMap/map.css';

    event ControlReady();
    procedure ClearRoute();
    procedure RenderRoute(GeoJson: Text; FromLat: Decimal; FromLon: Decimal; ToLat: Decimal; ToLon: Decimal);
}
