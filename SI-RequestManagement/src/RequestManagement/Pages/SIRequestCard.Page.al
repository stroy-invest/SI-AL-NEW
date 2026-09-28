page 52012 "SI Request Card"
{
    PageType = Document;
    SourceTable = "SI Request Header";
    ApplicationArea = All;
    Caption = 'Заявка на постачання';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Execution Date"; Rec."Execution Date")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                }

                field("Construction Object No."; Rec."Construction Object No.")
                {
                    ApplicationArea = All;
                    Editable = IsRequestEditable;
                }

                field("Requester User ID"; Rec."Requester User ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Requester Employee No."; Rec."Requester Employee No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Requester Employee Name"; Rec."Requester Employee Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = IsRequestEditable;
                }
            }

            part(RequestLines; "SI Request Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Request No." = field("No.");
                Editable = IsRequestEditable;
            }

            part(StatusLog; "SI Req. Status Log Part")
            {
                ApplicationArea = All;
                SubPageLink = "Request No." = field("No.");
                Editable = false;
            }
        }

        area(FactBoxes)
        {
            part(Attachments; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Вкладення';
                SubPageLink =
                    "Table ID" = const(Database::"SI Request Header"),
                    "No." = field("No.");
            }

            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Caption = 'Нотатки';
            }

            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Caption = 'Посилання';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Submit)
            {
                ApplicationArea = All;
                Caption = 'Подати на погодження';
                ToolTip = 'Надсилає заявку на погодження відповідно до налаштованого маршруту.';
                Image = SendApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = CanSubmit;

                trigger OnAction()
                var
                    RequestStatusMgt: Codeunit "SI Request Status Mgt.";
                begin
                    RequestStatusMgt.Submit(Rec);
                    CurrPage.Update(false);
                end;
            }

            group(Approval)
            {
                Caption = 'Погодження';

                action(ApproveRequest)
                {
                    ApplicationArea = All;
                    Caption = 'Погодити';
                    ToolTip = 'Погоджує заявку та передає її наступному погоджувачу або завершує погодження.';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CanApproveReject;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId());
                        CurrPage.Close();
                    end;
                }

                action(ReturnForRevision)
                {
                    ApplicationArea = All;
                    Caption = 'Повернути на доопрацювання';
                    ToolTip = 'Повертає заявку ініціатору для виправлення або доповнення.';
                    Image = Return;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CanApproveReject;

                    trigger OnAction()
                    var
                        ResolutionDialog: Page "SI Request Resolution Dialog";
                        RequestStatusMgt: Codeunit "SI Request Status Mgt.";
                        ResolutionReason: Text[250];
                    begin
                        if ResolutionDialog.RunModal() <> Action::OK then
                            exit;

                        ResolutionReason :=
                            ResolutionDialog.GetResolutionReason();

                        RequestStatusMgt.ReturnForRevision(
                            Rec,
                            ResolutionReason);

                        CurrPage.Close();
                    end;
                }

                action(RejectRequest)
                {
                    ApplicationArea = All;
                    Caption = 'Відхилити';
                    ToolTip = 'Остаточно відхиляє заявку.';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CanApproveReject;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId());
                        CurrPage.Close();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPageState();
    end;

    local procedure SetPageState()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalEntry: Record "Approval Entry";
    begin
        IsRequestEditable :=
            Rec.Status in
            [
                Rec.Status::Draft,
                Rec.Status::Returned
            ];

        CanSubmit :=
            Rec.Status in
            [
                Rec.Status::Draft,
                Rec.Status::Returned
            ];

        CanApproveReject :=
            (Rec.Status = Rec.Status::"Pending Approval") and
            ApprovalsMgmt.FindOpenApprovalEntryForCurrUser(
                ApprovalEntry,
                Rec.RecordId());
    end;

    var
        IsRequestEditable: Boolean;
        CanSubmit: Boolean;
        CanApproveReject: Boolean;
}