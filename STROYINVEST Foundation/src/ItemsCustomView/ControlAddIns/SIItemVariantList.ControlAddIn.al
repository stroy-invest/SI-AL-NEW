controladdin "SI Item Variant List"
{
    RequestedHeight = 135;
    RequestedWidth = 1000;
    MinimumHeight = 115;
    MinimumWidth = 700;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/ControlAddIns/SIItemVariantList.js';

    StartupScript =
        'src/ItemsCustomView/ControlAddIns/SIItemVariantListStartup.js';

    event ControlReady();
    event VariantSelected(ItemNo: Text; VariantCode: Text);
    event VariantOpenRequested(ItemNo: Text; VariantCode: Text);

    procedure RenderVariants(VariantsJson: Text);
}
