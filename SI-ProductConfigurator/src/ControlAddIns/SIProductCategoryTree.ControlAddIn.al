controladdin "SI Product Category Tree"
{
    RequestedHeight = 360;
    RequestedWidth = 620;
    MinimumHeight = 300;
    MinimumWidth = 420;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'src/ControlAddIns/SIProductCategoryTree.js';

    StartupScript =
        'src/ControlAddIns/SIProductCategoryTreeStartup.js';

    event ControlReady();
    event NodeSelected(CategoryCode: Text);

    procedure RenderTree(TreeJson: Text);
}
