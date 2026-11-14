controladdin "SI Adaptive Item Hierarchy"
{
    RequestedHeight = 650;
    RequestedWidth = 900;
    MinimumHeight = 300;
    MinimumWidth = 360;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/AdaptiveWorkspace/SIAdaptiveCategory.js',
        'src/ItemsCustomView/AdaptiveWorkspace/SIAdaptiveProduct.js',
        'src/ItemsCustomView/AdaptiveWorkspace/SIAdaptiveLayout.js';
    StartupScript = 'src/ItemsCustomView/AdaptiveWorkspace/SIAdaptiveStartup.js';

    event ControlReady();
    event NodeSelected(GroupCode: Text);
    event NodeOpenRequested(GroupCode: Text);
    event AddCategoryRequested(GroupCode: Text);
    event DeleteCategoryRequested(GroupCode: Text);
    event ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text);
    event ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text);

    procedure RenderTree(TreeJson: Text);
    procedure SelectNode(GroupCode: Text);
    procedure SetSelectionMode(IsSelectionMode: Boolean);
    procedure RenderProducts(ProductTreeJson: Text);
    procedure SelectProduct(NodeType: Text; ItemNo: Text; VariantCode: Text);
}
