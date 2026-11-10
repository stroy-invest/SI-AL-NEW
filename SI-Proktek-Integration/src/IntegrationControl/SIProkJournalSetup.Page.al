page 57120 "SI Prok Journal Setup"
{
    PageType = Card;
    SourceTable = "SI Prok Journal Setup";
    Caption = 'Налаштування виробничих журналів Proktek';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(Output)
            {
                Caption = 'Output Journal';
                field("Output Template"; Rec."Output Template") { ApplicationArea = All; }
                field("Output Batch"; Rec."Output Batch") { ApplicationArea = All; }
            }
            group(Consumption)
            {
                Caption = 'Consumption Journal';
                field("Consumption Template"; Rec."Consumption Template") { ApplicationArea = All; }
                field("Consumption Batch"; Rec."Consumption Batch") { ApplicationArea = All; }
            }
        }
    }
    trigger OnOpenPage()
    begin
        if not Rec.Get('DEFAULT') then begin
            Rec.Init();
            Rec."Primary Key" := 'DEFAULT';
            Rec.Insert(true);
        end;
    end;
}
