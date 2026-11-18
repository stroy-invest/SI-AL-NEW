page 65004 "SI IW Vehicle Capacity Part"
{
    PageType = ListPart;
    SourceTable = "SI Vehicle Capacity";
    Caption = 'Характеристики транспорту';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Capacities)
            {
                field(CapacityTypeDescription; CapacityTypeDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Характеристика';
                    ToolTip = 'Найменування характеристики транспортного засобу.';
                    Editable = false;
                }

                field("Nominal Quantity"; Rec."Nominal Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Actual Quantity"; Rec."Actual Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CapacityType: Record "SI Vehicle Capacity Type";
    begin
        Clear(CapacityTypeDescription);

        if CapacityType.Get(Rec."Capacity Type Code") then
            CapacityTypeDescription := CapacityType.Description;
    end;

    var
        CapacityTypeDescription: Text[100];
}
