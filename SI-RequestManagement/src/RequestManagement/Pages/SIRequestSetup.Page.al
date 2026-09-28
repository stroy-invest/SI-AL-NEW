page 52004 "SI Request Setup"
{
    PageType = Card;
    SourceTable = "SI Request Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI Request Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Request Nos."; Rec."Request Nos.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();

        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
    end;
}