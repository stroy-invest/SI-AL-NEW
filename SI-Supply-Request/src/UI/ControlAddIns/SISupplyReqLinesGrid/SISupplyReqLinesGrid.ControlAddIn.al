controladdin SISupplyReqLinesGrid
{
    RequestedHeight = 260; MinimumHeight = 180; MaximumHeight = 420; RequestedWidth = 1200; MinimumWidth = 700; HorizontalStretch = true; VerticalStretch = false;
    Scripts = 'src/UI/ControlAddIns/SISupplyReqLinesGrid/SISupplyReqLinesGrid.js';
    StartupScript = 'src/UI/ControlAddIns/SISupplyReqLinesGrid/SISupplyReqLinesGridStartup.js';
    StyleSheets = 'src/UI/ControlAddIns/SISupplyReqLinesGrid/SISupplyReqLinesGrid.css';
    event ControlReady(); event AddLine(); event EditLine(LineNo: Integer); event DeleteLine(LineNo: Integer);
    procedure SetLines(Data: Text; CanEdit: Boolean);
}
