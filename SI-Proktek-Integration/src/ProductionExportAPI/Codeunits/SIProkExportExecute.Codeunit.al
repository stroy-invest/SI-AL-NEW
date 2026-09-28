codeunit 57084 "SI Prok Export Execute"
{
    TableNo = "SI Prok Export Request";
    Permissions =
        tabledata "SI Prok Export Request" = RIMD,
        tabledata "SI Prok Production Export" = RIMD,
        tabledata "SI Prok Connection" = R,
        tabledata "SI Prok Session" = RIMD;

    trigger OnRun()
    var
        ExportEntry: Record "SI Prok Production Export";
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        ErrorText: Text;
    begin
        ExportMgt.GenerateNew(
            Rec."Date From",
            Rec."Date To",
            'PROKTEK-PROD',
            ExportEntry);

        Rec."Export Entry No." := ExportEntry."Entry No.";
        Rec."Production Count" := ExportEntry."Production Count";
        Rec."Total Volume M3" := ExportEntry."Total Volume M3";
        Rec."Finished At" := CurrentDateTime;

        if ExportEntry.Status = ExportEntry.Status::Ready then begin
            Rec.Status := Rec.Status::Completed;
            Clear(Rec."Error Message");
            Rec.Modify(true);
            exit;
        end;

        ErrorText := ExportEntry."Error Message";
        if ErrorText = '' then
            ErrorText := 'Production Export завершився зі статусом Error без тексту помилки.';

        Rec.Status := Rec.Status::Failed;
        Rec."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(Rec."Error Message"));
        Rec.Modify(true);
    end;
}
