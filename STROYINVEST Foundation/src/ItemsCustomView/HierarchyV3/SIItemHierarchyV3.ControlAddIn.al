controladdin "SI Item Hierarchy V3"
{
    RequestedHeight = 650;
    RequestedWidth = 900;
    MinimumHeight = 300;
    MinimumWidth = 360;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/HierarchyV3/V3SIAdaptiveCategory.js',
        'src/ItemsCustomView/HierarchyV3/V3SIAdaptiveProduct.js',
        'src/ItemsCustomView/HierarchyV3/SIHierarchyV3Layout.js';
    StartupScript = 'src/ItemsCustomView/HierarchyV3/V3SIAdaptiveStartup.js';

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
    procedure RenderParameters(ParametersJson: Text);
    procedure SetParametersVisible(IsVisible: Boolean);
}
