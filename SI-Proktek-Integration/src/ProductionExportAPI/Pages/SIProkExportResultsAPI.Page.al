page 57084 "SI Prok Export Results API"
{
    PageType = API;
    APIPublisher = 'stroyinvest';
    APIGroup = 'proktek';
    APIVersion = 'v1.0';
    EntityName = 'productionExportResult';
    EntitySetName = 'productionExportResults';
    EntityCaption = 'Proktek Production Export Result';
    EntitySetCaption = 'Proktek Production Export Results';
    SourceTable = "SI Prok Export Request";
    ODataKeyFields = SystemId;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(finishedAt; Rec."Finished At")
                {
                    Caption = 'Finished At';
                    Editable = false;
                }
                field(productionCount; Rec."Production Count")
                {
                    Caption = 'Production Count';
                    Editable = false;
                }
                field(totalVolumeM3; Rec."Total Volume M3")
                {
                    Caption = 'Total Volume M3';
                    Editable = false;
                }
                field(resultJson; ResultJson)
                {
                    Caption = 'Result JSON';
                    Editable = false;
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ExportEntry: Record "SI Prok Production Export";
    begin
        Clear(ResultJson);

        if Rec.Status <> Rec.Status::Completed then
            exit;
        if Rec."Export Entry No." = 0 then
            exit;
        if not ExportEntry.Get(Rec."Export Entry No.") then
            exit;

        ResultJson := ExportEntry.GetPayload();
    end;

    var
        ResultJson: Text;
}
