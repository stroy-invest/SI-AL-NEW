page 52011 "SI Request List"
{
    PageType = List;
    SourceTable = "SI Request Header";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Заявки на постачання';
    CardPageId = "SI Request Card";

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = All;
                }

                field("Execution Date"; Rec."Execution Date")
                {
                    ApplicationArea = All;
                }

                field("Construction Object No."; Rec."Construction Object No.")
                {
                    ApplicationArea = All;
                }

                field("Requester User ID"; Rec."Requester User ID")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
