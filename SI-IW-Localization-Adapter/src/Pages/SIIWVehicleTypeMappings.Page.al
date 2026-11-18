
page 65002 "SI IW Vehicle Type Mappings"
{
    PageType = List;
    SourceTable = "SI IW Vehicle Type Mapping";

    Caption = 'SI IW Vehicle Type Mappings';
    ApplicationArea = All;
    UsageCategory = Administration;

    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field(SIVehicleTypeCode; Rec."SI Vehicle Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SI vehicle type.';
                }

                field(IWVehicleCategory; Rec."IW Vehicle Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the corresponding IW vehicle category.';
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enables this mapping for vehicle synchronization.';
                }
            }
        }
    }
}
