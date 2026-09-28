page 52055 "SI Requester Inbox"
{
    Caption = 'Мої заявки';
    PageType = List;
    SourceTable = "SI Request Inbox Buffer";
    SourceTableTemporary = true;

    UsageCategory = Lists;
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер заявки.';
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає заявку.';
                }

                field("Request Status"; Rec."Request Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає поточний статус заявки.';
                }

                field("Execution Date"; Rec."Execution Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату виконання заявки.';
                }

                field("Current Approver Name"; Rec."Current Approver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає погоджувача, у якого заявка зараз перебуває на погодженні.';
                }

                field("Final Approver Name"; Rec."Final Approver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає погоджувача, який виконав остаточну дію із заявкою.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenRequest)
            {
                Caption = 'Відкрити';
                ApplicationArea = All;
                Image = Navigate;
                ToolTip = 'Відкриває вибрану заявку.';

                trigger OnAction()
                var
                    RequestHeader: Record "SI Request Header";
                begin
                    if not RequestHeader.Get(
                        Rec."Request No.")
                    then
                        Error(
                            RequestNotFoundErr,
                            Rec."Request No.");

                    Page.Run(
                        Page::"SI Request Card",
                        RequestHeader);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenRequestPromoted; OpenRequest)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        RequestInboxMgt: Codeunit "SI Request Inbox Mgt.";
    begin
        RequestInboxMgt.LoadRequesterInbox(Rec);

        Rec.SetCurrentKey("Request Status");

        if HasInitialStatusFilter then
            Rec.SetRange(
                "Request Status",
                InitialStatusFilter);

        if Rec.FindFirst() then;
    end;

    procedure SetRequestStatusFilter(
        RequestStatus: Enum "SI Request Status")
    begin
        InitialStatusFilter := RequestStatus;
        HasInitialStatusFilter := true;
    end;

    var
        InitialStatusFilter: Enum "SI Request Status";
        HasInitialStatusFilter: Boolean;

        RequestNotFoundErr:
            Label 'Заявку %1 не знайдено.';
}