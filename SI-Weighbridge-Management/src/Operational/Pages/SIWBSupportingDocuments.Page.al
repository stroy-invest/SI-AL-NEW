page 59110 "SI WB Supporting Documents"
{
    PageType = ListPart;
    SourceTable = "SI WB Supporting Document";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Супровідні документи';

    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = false;

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип документа';
                    Width = 24;
                }

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = '№ документа';
                    Width = 22;
                }

                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'Дата';
                    Width = 12;
                }

                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Caption = 'Файл';
                    Editable = false;
                    Width = 28;

                    trigger OnDrillDown()
                    begin
                        DownloadAttachment();
                    end;
                }

                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    Caption = 'Примітка';
                    Width = 32;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddFile)
            {
                ApplicationArea = All;
                Caption = 'Додати файл';
                Image = Attach;

                trigger OnAction()
                begin
                    UploadAttachment();
                end;
            }

            action(OpenFile)
            {
                ApplicationArea = All;
                Caption = 'Відкрити';
                Image = View;

                trigger OnAction()
                begin
                    DownloadAttachment();
                end;
            }

            action(DeleteDocument)
            {
                ApplicationArea = All;
                Caption = 'Видалити';
                Image = Delete;

                trigger OnAction()
                begin
                    Rec.TestField("Document Entry No.");
                    Rec.TestField("Line No.");

                    if not Confirm(
                        'Видалити супровідний документ "%1"?',
                        false,
                        Format(Rec."Document Type"))
                    then
                        exit;

                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    local procedure UploadAttachment()
    var
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        Rec.TestField("Document Entry No.");
        Rec.TestField("Line No.");

        if not UploadIntoStream(
            'Виберіть файл',
            '',
            'Усі файли (*.*)|*.*',
            FileName,
            InStr)
        then
            exit;

        Rec.Attachment.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        Rec."File Name" :=
            CopyStr(
                FileName,
                1,
                MaxStrLen(Rec."File Name"));

        Rec.Modify(true);
        CurrPage.Update(false);
    end;

    local procedure DownloadAttachment()
    var
        InStr: InStream;
        FileName: Text;
    begin
        Rec.CalcFields(Attachment);

        if not Rec.Attachment.HasValue() then
            Error('Для цього документа файл не додано.');

        Rec.Attachment.CreateInStream(InStr);

        FileName := Rec."File Name";
        if FileName = '' then
            FileName := 'attachment';

        DownloadFromStream(
            InStr,
            '',
            '',
            '',
            FileName);
    end;
}
