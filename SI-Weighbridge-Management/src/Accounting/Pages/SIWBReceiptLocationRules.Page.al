page 59132 "SI WB Receipt Location Rules"
{
    PageType = ListPart;
    SourceTable = "SI WB Receipt Location Rule";
    Caption = 'Правила прибуткування за замовчуванням';
    ApplicationArea = All;
    DelayedInsert = true;
    PopulateAllFields = true;

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field(Priority; Rec.Priority)
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

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
