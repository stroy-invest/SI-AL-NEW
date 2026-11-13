controladdin "SI Prok Shipment Tree"
{
    RequestedHeight = 650;
    RequestedWidth = 1200;
    MinimumHeight = 400;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;
    Scripts = 'SIProkShipmentTree.js';
    StartupScript = 'SIProkShipmentTreeStartup.js';

    event Ready();
    event RowOpened(RowType: Text; EntryNo: Integer);
    procedure RenderTree(TreeJson: Text);
}
