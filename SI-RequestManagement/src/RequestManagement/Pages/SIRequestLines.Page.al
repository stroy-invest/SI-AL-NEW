page 52013 "SI Request Lines"
{
    PageType = ListPart;
    SourceTable = "SI Request Line";
    ApplicationArea = All;
    Caption = 'Рядки заявки';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }

                field("SI Category Kind"; Rec."SI Category Kind")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}