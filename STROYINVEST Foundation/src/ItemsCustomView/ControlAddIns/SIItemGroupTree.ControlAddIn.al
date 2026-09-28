controladdin "SI Item Group Tree"
{
    RequestedHeight = 300;
    RequestedWidth = 1000;
    MinimumHeight = 280;
    MinimumWidth = 700;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/ControlAddIns/SIItemGroupTree.js';

    StartupScript =
        'src/ItemsCustomView/ControlAddIns/SIItemGroupTreeStartup.js';

    event ControlReady();
    event NodeSelected(GroupCode: Text);
    event NodeOpenRequested(GroupCode: Text);
    event AddCategoryRequested(GroupCode: Text);
    event DeleteCategoryRequested(GroupCode: Text);

    procedure RenderTree(TreeJson: Text);
    procedure SelectNode(GroupCode: Text);
    procedure SetSelectionMode(IsSelectionMode: Boolean);
}
