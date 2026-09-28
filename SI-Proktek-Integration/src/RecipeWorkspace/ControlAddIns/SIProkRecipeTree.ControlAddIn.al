controladdin "SI Prok Recipe Tree"
{
    RequestedHeight = 600;
    RequestedWidth = 1200;
    MinimumHeight = 350;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;
    Scripts = 'SIProkRecipeTree.js';
    StartupScript = 'SIProkRecipeTreeStartup.js';

    event Ready();
    event NodeSelected(NodeType: Text; NodeId: Text);
    event NodeOpened(NodeType: Text; NodeId: Text);
    procedure RenderTree(TreeJson: Text);
    procedure ExpandAll();
    procedure CollapseAll();
}
