page 57085 "SI Prok Export Requests"
{
    Caption = 'Proktek Production Export API Requests';
    PageType = List;
    SourceTable = "SI Prok Export Request";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(RequestId; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Request ID';
                }
                field("Date From"; Rec."Date From")
                {
                    ApplicationArea = All;
                }
                field("Date To"; Rec."Date To")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                }
                field("Finished At"; Rec."Finished At")
                {
                    ApplicationArea = All;
                }
                field("Job Queue Entry ID"; Rec."Job Queue Entry ID")
                {
                    ApplicationArea = All;
                }
                field("Export Entry No."; Rec."Export Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Production Count"; Rec."Production Count")
                {
                    ApplicationArea = All;
                }
                field("Total Volume M3"; Rec."Total Volume M3")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Повторити';
                Image = Refresh;

                trigger OnAction()
                var
                    RequestMgt: Codeunit "SI Prok Export Request Mgt.";
                begin
                    if Rec.Status <> Rec.Status::Failed then
                        Error('Повторити можна лише запит зі статусом Failed.');
                    RequestMgt.Requeue(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenExport)
            {
                ApplicationArea = All;
                Caption = 'Відкрити архівний експорт';
                Image = View;

                trigger OnAction()
                var
                    ExportEntry: Record "SI Prok Production Export";
                begin
                    if Rec."Export Entry No." = 0 then
                        Error('Для цього запиту ще немає архівного експорту.');
                    if not ExportEntry.Get(Rec."Export Entry No.") then
                        exit;
                    Page.Run(Page::"SI Prok Production Exports", ExportEntry);
                end;
            }
        }
    }
}
