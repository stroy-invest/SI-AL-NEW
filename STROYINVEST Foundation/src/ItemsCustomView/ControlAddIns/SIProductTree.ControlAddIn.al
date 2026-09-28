controladdin "SI Product Tree"
{
    RequestedHeight = 300;
    RequestedWidth = 1000;
    MinimumHeight = 240;
    MinimumWidth = 700;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/ControlAddIns/SIProductTree.js';

    StartupScript =
        'src/ItemsCustomView/ControlAddIns/SIProductTreeStartup.js';

    event ControlReady();
    event ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text);
    event ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text);

    procedure RenderProducts(ProductTreeJson: Text);
    procedure SelectProduct(NodeType: Text; ItemNo: Text; VariantCode: Text);
}
