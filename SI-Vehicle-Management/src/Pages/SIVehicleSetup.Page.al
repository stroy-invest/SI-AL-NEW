page 63257 "SI Vehicle Setup"
{
    PageType = Card;
    SourceTable = "SI Vehicle Setup";
    Caption = 'Налаштування транспорту';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Нумерація';
                field("Vehicle Nos."; Rec."Vehicle Nos.") { ApplicationArea = All; }
            }
        }
    }
    trigger OnOpenPage()
    begin
        if not Rec.Get('SETUP') then begin
            Rec.Init();
            Rec."Primary Key" := 'SETUP';
            Rec.Insert();
        end;
    end;
}
