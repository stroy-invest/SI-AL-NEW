
page 57099 "SI Prok Raw API Response Card"
{
    PageType = Card;
    SourceTable = "SI Prok Raw API Response";
    Caption = 'Архівна відповідь Proktek';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Received At"; Rec."Received At") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("API Operation"; Rec."API Operation") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
            }
            group(Intake)
            {
                Caption = 'Приймання та обробка';
                field("Processing Status"; Rec."Processing Status") { ApplicationArea = All; }
                field("Intake Result"; Rec."Intake Result") { ApplicationArea = All; }
                field("Production Fact Entry No."; Rec."Production Fact Entry No.") { ApplicationArea = All; }
            }
            group(Diagnostics)
            {
                Caption = 'Діагностика';
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Технічне повідомлення. Може містити діагностику успішного приймання.';
                }
            }
            group(Payload)
            {
                Caption = 'Первинний JSON';
                field(RawJsonText; RawJsonText)
                {
                    ApplicationArea = All;
                    Caption = 'JSON';
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Незмінений текст первинної відповіді Proktek.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReplayExisting)
            {
                ApplicationArea = All;
                Caption = 'Повторити приймання (Existing)';
                Image = Refresh;
                Enabled = Rec."Capture Mode" = Rec."Capture Mode"::Test;
                trigger OnAction()
                var
                    ReplayMgt: Codeunit "SI Prok Intake Replay Mgt.";
                begin
                    if not Confirm('Повторити приймання архіву №%1 без зміни UUID?', false, Rec."Entry No.") then
                        exit;
                    ReplayMgt.Replay(Rec."Entry No.", false);
                    CurrPage.Update(false);
                end;
            }
            action(ReplayConflict)
            {
                ApplicationArea = All;
                Caption = 'Тест конфлікту UUID';
                Image = Warning;
                Enabled = Rec."Capture Mode" = Rec."Capture Mode"::Test;
                trigger OnAction()
                var
                    ReplayMgt: Codeunit "SI Prok Intake Replay Mgt.";
                begin
                    if not Confirm('Створити тестовий Conflict для архіву №%1? Початковий факт не змінюється.', false, Rec."Entry No.") then
                        exit;
                    ReplayMgt.Replay(Rec."Entry No.", true);
                    CurrPage.Update(false);
                end;
            }
            action(OpenProductionFact)
            {
                ApplicationArea = All;
                Caption = 'Відкрити виробничий факт';
                Image = View;
                Enabled = Rec."Production Fact Entry No." <> 0;
                trigger OnAction()
                var
                    Fact: Record "SI Prok Production Fact";
                begin
                    if Fact.Get(Rec."Production Fact Entry No.") then
                        Page.Run(Page::"SI Prok Production Fact Card", Fact)
                    else
                        Message('Пов’язаний виробничий факт %1 не знайдено.', Rec."Production Fact Entry No.");
                end;
            }
            action(DownloadRaw)
            {
                ApplicationArea = All;
                Caption = 'Завантажити первинний JSON';
                Image = Download;
                trigger OnAction()
                var
                    InputStream: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Raw JSON");
                    if not Rec."Raw JSON".HasValue() then
                        exit;
                    Rec."Raw JSON".CreateInStream(InputStream, TextEncoding::UTF8);
                    FileName := StrSubstNo('Proktek_Raw_%1.json', Rec."Entry No.");
                    DownloadFromStream(InputStream, '', '', '', FileName);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RawJsonText := Rec.GetRaw();
    end;

    var
        RawJsonText: Text;
}
