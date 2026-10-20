page 70025 "SI Audit Request Log Card"
{
    PageType = Card;
    SourceTable = "SI Audit Request Log";
    Caption = 'Картка реєстрового запиту';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Identification)
            {
                Caption = 'Ідентифікація запиту';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Batch No."; Rec."Batch No.") { ApplicationArea = All; }
                field("Audit Entry No."; Rec."Audit Entry No.") { ApplicationArea = All; }
                field(EDRPOU; Rec.EDRPOU) { ApplicationArea = All; }
                field(Code1C; Rec.Code1C) { ApplicationArea = All; }
                field("Attempt No."; Rec."Attempt No.") { ApplicationArea = All; }
                field("Request Correlation ID"; Rec."Request Correlation ID") { ApplicationArea = All; }
            }
            group(Transport)
            {
                Caption = 'HTTP / EDS';
                field("Requested At"; Rec."Requested At") { ApplicationArea = All; }
                field("Completed At"; Rec."Completed At") { ApplicationArea = All; }
                field("EDS Provider Code"; Rec."EDS Provider Code") { ApplicationArea = All; }
                field("EDS Operation Code"; Rec."EDS Operation Code") { ApplicationArea = All; }
                field("HTTP Status Code"; Rec."HTTP Status Code") { ApplicationArea = All; }
                field("Response Content Type"; Rec."Response Content Type") { ApplicationArea = All; }
            }
            group(Outcome)
            {
                Caption = 'Результат';
                field("Retrieval Result"; Rec."Retrieval Result") { ApplicationArea = All; }
                field("Verification Result"; Rec."Verification Result") { ApplicationArea = All; }
                field("Response Message"; Rec."Response Message") { ApplicationArea = All; MultiLine = true; }
            }
            group(Payload)
            {
                Caption = 'Оригінальна відповідь';
                field(OriginalBytesPresent; OriginalBytesPresent)
                {
                    Caption = 'Оригінальні HTTP-байти збережено';
                    ApplicationArea = All;
                }
                field(DecodedXmlPreview; DecodedXmlPreview)
                {
                    Caption = 'XML (прочитаний з оригінальних байтів)';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Перегляд XML після розбору вихідного потоку з урахуванням його кодування. Оригінал завантажується окремою дією.';
                }
                field(PayloadNote; PayloadNote)
                {
                    Caption = 'Примітка';
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadRawBytes)
            {
                Caption = 'Завантажити оригінал (.bin)';
                ApplicationArea = All;
                Image = Export;
                trigger OnAction()
                var
                    RawIn: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Raw HTTP Bytes");
                    if not Rec."Raw HTTP Bytes".HasValue() then
                        Error('Запис № %1 не містить оригінальних HTTP-байтів.', Rec."Entry No.");
                    Rec."Raw HTTP Bytes".CreateInStream(RawIn);
                    FileName := StrSubstNo('adm_tools_%1_log_%2.bin', Rec.EDRPOU, Rec."Entry No.");
                    DownloadFromStream(RawIn, 'Оригінальна відповідь', '', 'Binary files (*.bin)|*.bin', FileName);
                end;
            }
            action(MaterializeRawXml)
            {
                Caption = 'Повторно матеріалізувати XML';
                ApplicationArea = All;
                Image = Process;
                trigger OnAction()
                var
                    AuditEntry: Record "SI Audit Entry";
                    Materializer: Codeunit "SI Audit XML Materializer";
                begin
                    Rec.CalcFields("Raw HTTP Bytes");
                    if not Rec."Raw HTTP Bytes".HasValue() then
                        Error('Немає оригінальних HTTP-байтів.');
                    if not AuditEntry.Get(Rec."Batch No.", Rec."Audit Entry No.") then
                        Error('Не знайдено запис пакета.');
                    Materializer.Process(AuditEntry, Rec);
                    CurrPage.Update(false);
                    Message('XML опрацьовано. Результат: %1.', Rec."Verification Result");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Doc: XmlDocument;
        RawIn: InStream;
    begin
        Clear(DecodedXmlPreview);
        Clear(PayloadNote);
        Rec.CalcFields("Raw HTTP Bytes", "Raw Response");
        OriginalBytesPresent := Rec."Raw HTTP Bytes".HasValue();
        if OriginalBytesPresent then begin
            Rec."Raw HTTP Bytes".CreateInStream(RawIn);
            if XmlDocument.ReadFrom(RawIn, Doc) then begin
                Doc.WriteTo(DecodedXmlPreview);
                exit;
            end;
            PayloadNote := 'Оригінальні байти є, але XML-парсер не зміг прочитати їх. Завантажте .bin для діагностики.';
            exit;
        end;
        if Rec."Raw Response".HasValue() then
            PayloadNote := 'Є лише історичний текстовий Raw Response. Він міг бути декодований неправильно. Оригінальних HTTP-байтів немає.'
        else
            PayloadNote := 'Тіло відповіді не збережено.';
    end;

    var
        OriginalBytesPresent: Boolean;
        DecodedXmlPreview: Text;
        PayloadNote: Text;
}
