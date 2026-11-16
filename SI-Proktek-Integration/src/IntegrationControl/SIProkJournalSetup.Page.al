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
            group(ProcessProduction)
            {
                Caption = 'SI Process Production (MVP)';
                field("Process Template"; Rec."Process Template") { ApplicationArea = All; }
                field("Process Batch"; Rec."Process Batch") { ApplicationArea = All; }
                field("Process Business Group"; Rec."Process Business Group") { ApplicationArea = All; }
            }
            group(DocumentNumbering)
            {
                Caption = 'Нумерація документів';
                field("Document No. Series"; Rec."Document No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Стандартна серія номерів BC. Один номер виділяється на один Production Fact і використовується в усіх його Output/Consumption.';
                }
            }
            group(PostingDates)
            {
                Caption = 'Дата бухгалтерського проведення';
                field("Posting Date Policy"; Rec."Posting Date Policy")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає Posting Date для нових журналів і для керованої зміни дати підготовлених журналів. Дата виробництва залишається незмінною.';
                }
                field("Specified Posting Date"; Rec."Specified Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Заповнюється, якщо обрано політику «Задана дата».';
                }
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
