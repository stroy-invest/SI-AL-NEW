page 50425 "SI EDS Inbound Event Card"
{
    PageType = Card;
    SourceTable = "SI EDS Inbound Event";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'EDS Inbound Event';

    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                }

                field("Event ID"; Rec."Event ID")
                {
                    ApplicationArea = All;
                }

                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = All;
                }

                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                }

                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }

            group(Processing)
            {
                Caption = 'Обробка';

                field("Processing Started At"; Rec."Processing Started At")
                {
                    ApplicationArea = All;
                }

                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }

                field("Processing Attempt Count"; Rec."Processing Attempt Count")
                {
                    ApplicationArea = All;
                }

                field(LastErrorText; LastErrorText)
                {
                    ApplicationArea = All;
                    Caption = 'Остання помилка';

                    MultiLine = true;
                }
            }

            group(Payload)
            {
                Caption = 'Payload';

                field(PayloadText; PayloadText)
                {
                    ApplicationArea = All;
                    Caption = 'JSON Payload';

                    MultiLine = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadBlobContent();
    end;

    local procedure LoadBlobContent()
    begin
        PayloadText := Rec.GetPayload();
        LastErrorText := Rec.GetLastError();
    end;

    var
        PayloadText: Text;
        LastErrorText: Text;
}