controladdin "SI Vehicle Model Tree"
{
    RequestedHeight = 650;
    RequestedWidth = 900;
    MinimumHeight = 320;
    MinimumWidth = 500;
    VerticalStretch = true;
    HorizontalStretch = true;
    Scripts = 'src/ControlAddIns/SIVehicleModelTree.js';
    StartupScript = 'src/ControlAddIns/SIVehicleModelTreeStartup.js';
    event ControlReady();
    event ModelOpenRequested(BrandCode: Text; ModelCode: Text);
    event ModelSelected(BrandCode: Text; ModelCode: Text);
    event SelectionCleared();
    event AddRequested(Kind: Text; TypeCode: Text; BrandCode: Text; ModelCode: Text);
    event DeleteRequested(Kind: Text; TypeCode: Text; BrandCode: Text; ModelCode: Text);
    procedure RenderTree(TreeJson: Text);
}
