controladdin "SI EDS Tree Grid"
{
    RequestedHeight = 600;
    RequestedWidth = 1200;
    MinimumHeight = 360;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'src/EDS/ControlAddIns/SIEDSTreeGrid.js';
    StartupScript = 'src/EDS/ControlAddIns/SIEDSTreeGridStartup.js';

    event ControlReady();
    event NodeSelected(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text);
    event NodeOpenRequested(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text);

    procedure Render(TreeJson: Text);
}
