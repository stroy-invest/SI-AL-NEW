page 70022 "SI Audit Request Logs"
{
    PageType = List;
    SourceTable = "SI Audit Request Log";
    Caption = 'SI Audit Request Logs';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "SI Audit Request Log Card";
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Batch No."; Rec."Batch No.") { ApplicationArea = All; }
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(EDRPOU; Rec.EDRPOU) { ApplicationArea = All; }
                field("Requested At"; Rec."Requested At") { ApplicationArea = All; }
                field("HTTP Status Code"; Rec."HTTP Status Code") { ApplicationArea = All; }
                field("EDS Provider Code"; Rec."EDS Provider Code") { ApplicationArea = All; }
                field("EDS Operation Code"; Rec."EDS Operation Code") { ApplicationArea = All; }
                field("Attempt No."; Rec."Attempt No.") { ApplicationArea = All; }
                field("Completed At"; Rec."Completed At") { ApplicationArea = All; }
                field("Retrieval Result"; Rec."Retrieval Result") { ApplicationArea = All; }
                field("Verification Result"; Rec."Verification Result") { ApplicationArea = All; }
                field("Response Message"; Rec."Response Message") { ApplicationArea = All; }
                field("Response Content Type"; Rec."Response Content Type") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenLogCard)
            {
                Caption = 'Відкрити картку журналу';
                ApplicationArea = All;
                Image = ViewDetails;
                RunObject = page "SI Audit Request Log Card";
                RunPageLink = "Entry No." = field("Entry No.");
            }
            action(MaterializeRawXml)
            {
                Caption = 'Матеріалізувати RAW XML';
                ApplicationArea = All;
                Image = Process;
                ToolTip = 'Розібрати оригінальні байти XML та заповнити лише лабораторні довідники.';
                trigger OnAction()
                var
                    AuditEntry: Record "SI Audit Entry";
                    Materializer: Codeunit "SI Audit XML Materializer";
                begin
                    Rec.CalcFields("Raw HTTP Bytes");
                    if not Rec."Raw HTTP Bytes".HasValue() then
                        Error('Запис № %1 не містить оригінальних HTTP-байтів.', Rec."Entry No.");
                    if not AuditEntry.Get(Rec."Batch No.", Rec."Audit Entry No.") then
                        Error('Не знайдено запис пакета для журналу № %1.', Rec."Entry No.");
                    Materializer.Process(AuditEntry, Rec);
                    CurrPage.Update(false);
                    Message('XML опрацьовано. Результат: %1.', Rec."Verification Result");
                end;
            }
            action(DownloadOriginalBytes)
            {
                Caption = 'Завантажити оригінальні байти HTTP';
                ApplicationArea = All;
                Image = Export;
                trigger OnAction()
                var
                    Source: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Raw HTTP Bytes");
                    if not Rec."Raw HTTP Bytes".HasValue() then begin
                        Message('У вибраному записі № %1 немає сирих HTTP-байтів. Виберіть запис RAW-DIAGNOSTIC або повторіть RAW GET.', Rec."Entry No.");
                        exit;
                    end;
                    Rec."Raw HTTP Bytes".CreateInStream(Source);
                    FileName := 'adm_tools_original_response.bin';
                    DownloadFromStream(Source, 'Оригінальна HTTP-відповідь', '', 'Binary files (*.bin)|*.bin', FileName);
                end;
            }
            action(ShowRawResponse)
            {
                Caption = 'Завантажити XML';
                ApplicationArea = All;
                Image = View;
                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Raw Response");
                    if not Rec."Raw Response".HasValue() then begin
                        Message('Тіло відповіді відсутнє.');
                        exit;
                    end;
                    Rec."Raw Response".CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := 'adm_tools_response.xml';
                    DownloadFromStream(InStr, 'Відповідь adm.tools', '', 'XML files (*.xml)|*.xml', FileName);
                end;
            }
        }
    }
}
