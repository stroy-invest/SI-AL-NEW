controladdin "SI VSC Tree View AddIn"
{
    RequestedHeight = 650;
    RequestedWidth = 1200;
    MinimumHeight = 450;
    MinimumWidth = 800;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'src/Procurement/ControlAddIns/SIVSCTreeView.js';
    StartupScript = 'src/Procurement/ControlAddIns/SIVSCTreeViewStartup.js';

    event ControlReady();
    event CapabilityOpenRequested(CapabilityCode: Text);

    procedure RenderTree(TreeJson: Text);
    procedure ExpandAll();
    procedure CollapseAll();
}
