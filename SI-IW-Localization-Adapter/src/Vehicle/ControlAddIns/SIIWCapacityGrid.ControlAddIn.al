controladdin "SI IW Capacity Grid"
{
    RequestedHeight = 160;
    MinimumHeight = 140;
    MaximumHeight = 180;
    HorizontalStretch = true;
    VerticalStretch = false;
    StyleSheets = 'src/Vehicle/ControlAddIns/capacity-grid.css';
    Scripts = 'src/Vehicle/ControlAddIns/capacity-grid.js';
    StartupScript = 'src/Vehicle/ControlAddIns/capacity-startup.js';

    event ControlReady();
    procedure SetData(DataJson: Text);
}
