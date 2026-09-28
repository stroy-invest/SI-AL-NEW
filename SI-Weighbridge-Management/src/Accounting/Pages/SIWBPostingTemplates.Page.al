page 59130 "SI WB Posting Templates"
{
    PageType = List;
    SourceTable = "SI WB Posting Template";
    Caption = 'Шаблони обліку вагової';
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "SI WB Posting Template Card";

    layout
    {
        area(Content)
        {
            repeater(Templates)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                }

                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }

                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                }

                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Операція редагується на картці шаблону, де діють залежні списки.';
                }

                field("Shipment Scenario"; Rec."Shipment Scenario")
                {
                    ApplicationArea = All;
                    Caption = 'Тип операції';
                    Editable = false;
                    ToolTip = 'Тип операції редагується на картці шаблону, де список залежить від операції.';
                }

                field("Basis Type"; Rec."Basis Type")
                {
                    ApplicationArea = All;
                }

                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                }

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
