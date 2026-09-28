controladdin "SI WB Compact Lines"
{
    Scripts =
        './Resources/Lines/compactLines.js';

    StartupScript =
        './Resources/Lines/startup.js';

    StyleSheets =
        './Resources/Common/siwbCompactGrid.css';

    RequestedHeight = 92;
    MinimumHeight = 82;
    MaximumHeight = 118;

    HorizontalStretch = true;
    HorizontalShrink = true;
    VerticalShrink = true;

    procedure SetData(DataJson: Text);

    event ControlReady();
    event AddLineRequested();
    event DeleteLineRequested(LineNo: Integer);
    event RecalculateRequested(LineNo: Integer);
    event ItemLookupRequested(LineNo: Integer);
    event VariantLookupRequested(LineNo: Integer);
    event AllocatedWeightChanged(LineNo: Integer; NewValue: Decimal);
}
