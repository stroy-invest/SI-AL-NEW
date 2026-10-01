controladdin "SI Classification Tree"
{
    RequestedHeight = 600;
    RequestedWidth = 480;
    MinimumHeight = 400;
    MinimumWidth = 320;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'src/ClassificationMgt/ControlAddIns/SIClassificationTree.js';

    StartupScript =
        'src/ClassificationMgt/ControlAddIns/SIClassificationTreeStartup.js';

    event ControlReady();

    event NodeSelected(
        SystemCode: Text;
        NodeCode: Text);

    procedure RenderTree(TreeJson: Text);

    procedure ClearTree();
}
