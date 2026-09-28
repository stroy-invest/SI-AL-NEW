controladdin "SI Classification Tree"
{
    RequestedHeight = 600;
    RequestedWidth = 480;
    MinimumHeight = 400;
    MinimumWidth = 320;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'ClassificationMgt/src/ControlAddIns/SIClassificationTree.js';

    StartupScript =
        'ClassificationMgt/src/ControlAddIns/SIClassificationTreeStartup.js';

    event ControlReady();

    event NodeSelected(
        SystemCode: Text;
        NodeCode: Text);

    procedure RenderTree(TreeJson: Text);

    procedure ClearTree();
}
