controladdin "SI VSC Category Tree"
{
    RequestedHeight = 500;
    RequestedWidth = 1000;
    MinimumHeight = 350;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'src/Procurement/ControlAddIns/SIVSCCategoryTree.js';
    StartupScript = 'src/Procurement/ControlAddIns/SIVSCCategoryTreeStartup.js';

    event ControlReady();
    event CategoryToggled(CategoryCode: Text; IsSelected: Boolean);

    procedure RenderTree(TreeJson: Text);
}
