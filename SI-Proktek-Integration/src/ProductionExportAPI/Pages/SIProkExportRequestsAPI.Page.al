page 57083 "SI Prok Export Requests API"
{
    PageType = API;
    APIPublisher = 'stroyinvest';
    APIGroup = 'proktek';
    APIVersion = 'v1.0';
    EntityName = 'productionExportRequest';
    EntitySetName = 'productionExportRequests';
    EntityCaption = 'Proktek Production Export Request';
    EntitySetCaption = 'Proktek Production Export Requests';
    SourceTable = "SI Prok Export Request";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = true;
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
                field(dateFrom; Rec."Date From")
                {
                    Caption = 'Date From';
                }
                field(dateTo; Rec."Date To")
                {
                    Caption = 'Date To';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
                    Editable = false;
                }
                field(startedAt; Rec."Started At")
                {
                    Caption = 'Started At';
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
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        RequestMgt: Codeunit "SI Prok Export Request Mgt.";
    begin
        RequestMgt.CreateAndEnqueue(Rec);
        exit(false);
    end;
}
