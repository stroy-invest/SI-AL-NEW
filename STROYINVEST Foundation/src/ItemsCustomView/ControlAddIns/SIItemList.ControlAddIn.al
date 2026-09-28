controladdin "SI Item List"
{
    RequestedHeight = 175;
    RequestedWidth = 1000;
    MinimumHeight = 150;
    MinimumWidth = 700;
    VerticalStretch = false;
    HorizontalStretch = true;

    Scripts =
        'src/ItemsCustomView/ControlAddIns/SIItemList.js';

    StartupScript =
        'src/ItemsCustomView/ControlAddIns/SIItemListStartup.js';

    event ControlReady();
    event ItemSelected(ItemNo: Text);
    event ItemOpenRequested(ItemNo: Text);

    procedure RenderItems(ItemsJson: Text);
}
