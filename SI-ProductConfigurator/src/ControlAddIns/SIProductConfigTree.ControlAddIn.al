controladdin "SI Product Config Tree"
{
    RequestedHeight = 620;
    RequestedWidth = 1100;
    MinimumHeight = 400;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'src/ControlAddIns/SIProductConfigTree.js';
    StartupScript = 'src/ControlAddIns/SIProductConfigTreeStartup.js';

    event ControlReady();
    event NodeSelected(NodeType: Text; ConfigurationNo: Text);
    event NodeOpen(ConfigurationNo: Text);
    event NodeCommand(CommandName: Text; ConfigurationNo: Text);

    procedure RenderTree(TreeJson: Text);
    procedure ExpandAll();
    procedure CollapseAll();
}
