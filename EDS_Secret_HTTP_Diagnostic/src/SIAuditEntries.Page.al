page 70021 "SI Audit Entries"
{
    PageType = List;
    SourceTable = "SI Audit Entry";
    Caption = 'SI Audit Entries';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "SI Audit Entry Card";
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Batch No."; Rec."Batch No.") { ApplicationArea = All; }
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Code1C; Rec.Code1C) { ApplicationArea = All; }
                field(EDRPOU; Rec.EDRPOU) { ApplicationArea = All; }
                field("Source Name"; Rec."Source Name") { ApplicationArea = All; }
                field("Source Legal Form"; Rec."Source Legal Form") { ApplicationArea = All; }
                field("Is FOP"; Rec."Is FOP") { ApplicationArea = All; }
                field("Source Excel Row"; Rec."Source Excel Row") { ApplicationArea = All; }
                field("Processing Status"; Rec."Processing Status") { ApplicationArea = All; }
                field("Result Code"; Rec."Result Code") { ApplicationArea = All; }
                field("Result Details"; Rec."Result Details") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DirectRawEncodingDiagnostic)
            {
                Caption = 'Діагностика RAW HTTP (без EDS)';
                ApplicationArea = All;
                Image = TestFile;
                ToolTip = 'Прямий GET до adm.tools; зберігає лише сирі байти та HTTP-заголовок. Не запускає матеріалізацію.';
                trigger OnAction()
                var
                    Diagnostic: Codeunit "SI Audit Encoding Diag";
                begin
                    Diagnostic.Probe(Rec);
                end;
            }
            action(TestOneGET)
            {
                Caption = 'Тест GET adm.tools (один ЄДРПОУ)';
                ApplicationArea = All;
                Image = TestFile;
                ToolTip = 'Виконати один GET через Foundation EDS і зберегти HTTP/XML у журналі. Не змінює BP.';
                trigger OnAction()
                var
                    Probe: Codeunit "SI Audit EDS GET Probe";
                begin
                    Probe.ExecuteOne(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
