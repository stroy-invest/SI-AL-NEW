page 57028 "SI Prok CPR FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Concrete Prod Request";
    Caption = 'Технічна інформація';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Audit)
            {
                Caption = 'Аудит';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(ProktekOrder)
            {
                Caption = 'Proktek Order';

                field("Proktek Order ID"; Rec."Proktek Order ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Proktek Order UUID"; Rec."Proktek Order UUID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Proktek Order Synced At"; Rec."Proktek Order Synced At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Proktek Last Message"; Rec."Proktek Last Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}
