page 50781 "SI EDS Config Transport"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'EDS: перенесення конфігурації';
    SourceTable = "SI EDS Service";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Information)
            {
                Caption = 'Конфігурація EDS';
                field(Instructions; Instructions)
                {
                    Caption = 'Призначення';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportEDS)
            {
                Caption = 'Експортувати JSON';
                Image = Export;
                trigger OnAction()
                var
                    Transport: Codeunit "SI EDS Config Transport";
                    Blob: Codeunit "Temp Blob";
                    OutS: OutStream;
                    InS: InStream;
                    FileName: Text;
                begin
                    Blob.CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText(Transport.ExportConfiguration());
                    Blob.CreateInStream(InS, TextEncoding::UTF8);
                    FileName := 'SI-EDS-Configuration.json';
                    DownloadFromStream(InS, 'EDS Configuration', '', 'JSON files (*.json)|*.json', FileName);
                end;
            }
            action(PreviewEDS)
            {
                Caption = 'Перевірити пакет (Dry Run)';
                Image = ViewDetails;
                trigger OnAction()
                begin
                    LoadAndRun(false);
                end;
            }
            action(ImportEDS)
            {
                Caption = 'Імпортувати пакет';
                Image = Import;
                trigger OnAction()
                begin
                    LoadAndRun(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Instructions := 'Експорт EDS без секретів. Імпорт створює/оновлює записи без видалення. Перед застосуванням виконайте Dry Run.';
    end;

    local procedure LoadAndRun(ApplyChanges: Boolean)
    var
        Transport: Codeunit "SI EDS Config Transport";
        InS: InStream;
        Utf8InS: InStream;
        OutS: OutStream;
        Blob: Codeunit "Temp Blob";
        FileName: Text;
        Payload: Text;
        LineText: Text;
        Summary: Text;
        Preview: Record "SI EDS Transport Preview" temporary;
    begin
        if not UploadIntoStream('Оберіть пакет EDS', '', 'JSON files (*.json)|*.json', FileName, InS) then
            exit;
        // UploadIntoStream does not allow selecting the text encoding.
        // Preserve the raw uploaded bytes, then explicitly decode as UTF-8.
        Blob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        Blob.CreateInStream(Utf8InS, TextEncoding::UTF8);
        // ReadText stops at a line ending; collect the entire JSON document.
        while not Utf8InS.EOS do begin
            Utf8InS.ReadText(LineText);
            Payload += LineText;
        end;
        Transport.AnalyzeConfiguration(Payload, false, Summary);
        if not ApplyChanges then begin
            Transport.BuildPreview(Payload, Preview);
            Message('Перевірка завершена. %1\Відкриється детальний перегляд. Кнопка "Тільки зміни" показує відмінності.', Summary);
            Page.RunModal(Page::"SI EDS Transport Preview", Preview);
            exit;
        end;
        if not Confirm('Застосувати конфігурацію EDS до поточної компанії?\%1\Секрети не імпортуються.', false, Summary) then
            exit;
        Transport.AnalyzeConfiguration(Payload, true, Summary);
        Message('Імпорт завершено. %1', Summary);
    end;

    var
        Instructions: Text[250];
}
