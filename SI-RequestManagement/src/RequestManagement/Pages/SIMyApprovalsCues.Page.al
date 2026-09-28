page 52032 "SI My Approvals Cues"
{
    PageType = CardPart;
    SourceTable = "SI My Approvals Cue";
    Caption = 'Мої заявки та погодження';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            cuegroup(MyRequests)
            {
                Caption = 'Мої заявки';

                field("My Draft Requests Count"; Rec."My Draft Requests Count")
                {
                    ApplicationArea = All;
                    Caption = 'Чернетки';
                    ToolTip = 'Показує чернетки заявок, створені поточним користувачем.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenMyRequests(
                            Enum::"SI Request Status"::Draft);
                    end;
                }

                field("My Pending Requests Count"; Rec."My Pending Requests Count")
                {
                    ApplicationArea = All;
                    Caption = 'На погодженні';
                    ToolTip = 'Показує заявки поточного користувача, які перебувають на погодженні.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenMyRequests(
                            Enum::"SI Request Status"::"Pending Approval");
                    end;
                }

                field("My Returned Requests Count"; Rec."My Returned Requests Count")
                {
                    ApplicationArea = All;
                    Caption = 'Повернено на доопрацювання';
                    ToolTip = 'Показує заявки поточного користувача, повернені на доопрацювання.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenMyRequests(
                            Enum::"SI Request Status"::Returned);
                    end;
                }
            }

            cuegroup(MyApprovals)
            {
                Caption = 'Мої погодження';

                field("Pending Approval Count"; Rec."Pending Approval Count")
                {
                    ApplicationArea = All;
                    Caption = 'Очікують рішення';
                    ToolTip = 'Показує відкриті заявки, які очікують рішення поточного користувача.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenPendingApprovals();
                    end;
                }

                field("Urgent Approval Count"; Rec."Urgent Approval Count")
                {
                    ApplicationArea = All;
                    Caption = 'Потребують термінового розгляду';
                    ToolTip = 'Показує відкриті погодження, строк розгляду яких настав або вже минув.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenUrgentApprovals();
                    end;
                }

                field("Approved Today Count"; Rec."Approved Today Count")
                {
                    ApplicationArea = All;
                    Caption = 'Погоджено сьогодні';
                    ToolTip = 'Показує заявки, погоджені поточним користувачем сьогодні.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        OpenApprovedToday();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitCueRecord();
        SetCueFilters();
    end;

    trigger OnAfterGetRecord()
    begin
        SetCueFilters();
    end;

    local procedure InitCueRecord()
    begin
        if Rec.Get('MAIN') then
            exit;

        Rec.Init();
        Rec."Primary Key" := 'MAIN';
        Rec.Insert();
    end;

    local procedure SetCueFilters()
    var
        StartOfToday: DateTime;
        StartOfTomorrow: DateTime;
    begin
        StartOfToday :=
            CreateDateTime(
                Today(),
                0T);

        StartOfTomorrow :=
            CreateDateTime(
                Today() + 1,
                0T);

        Rec.SetRange(
            "User ID Filter",
            UserId());

        Rec.SetFilter(
            "Today DateTime Filter",
            '%1..%2',
            StartOfToday,
            StartOfTomorrow);

        Rec.SetFilter(
            "Urgent Date Filter",
            '%1..%2',
            DMY2Date(1, 1, 1),
            Today());
    end;

    local procedure OpenMyRequests(
        RequestStatus: Enum "SI Request Status")
    var
        RequesterInbox: Page "SI Requester Inbox";
    begin
        RequesterInbox.SetRequestStatusFilter(
            RequestStatus);

        RequesterInbox.Run();
    end;

    local procedure OpenPendingApprovals()
    var
        ApproverInbox: Page "SI Request Approver Inbox";
    begin
        ApproverInbox.SetPendingOnly();
        ApproverInbox.Run();
    end;

    local procedure OpenUrgentApprovals()
    var
        ApproverInbox: Page "SI Request Approver Inbox";
    begin
        ApproverInbox.SetUrgentOnly();
        ApproverInbox.Run();
    end;

    local procedure OpenApprovedToday()
    var
        ApproverInbox: Page "SI Request Approver Inbox";
    begin
        ApproverInbox.SetApprovedTodayOnly();
        ApproverInbox.Run();
    end;
}