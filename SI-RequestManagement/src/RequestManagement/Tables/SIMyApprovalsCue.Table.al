table 52031 "SI My Approvals Cue"
{
    Caption = 'Мої заявки та погодження';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }

        // ---------------------------------------------------------
        // Мої погодження
        // ---------------------------------------------------------

        field(10; "Pending Approval Count"; Integer)
        {
            Caption = 'Очікують рішення';
            FieldClass = FlowField;
            CalcFormula = count("Approval Entry"
                where(
                    "Approver ID" = field("User ID Filter"),
                    Status = const(Open)
                ));
        }

        field(20; "Approved Today Count"; Integer)
        {
            Caption = 'Погоджено сьогодні';
            FieldClass = FlowField;
            CalcFormula = count("Approval Entry"
                where(
                    "Approver ID" = field("User ID Filter"),
                    Status = const(Approved),
                    "Last Date-Time Modified" = field("Today DateTime Filter")
                ));
        }

        field(30; "Urgent Approval Count"; Integer)
        {
            Caption = 'Потребують термінового розгляду';
            FieldClass = FlowField;
            CalcFormula = count("Approval Entry"
                where(
                    "Approver ID" = field("User ID Filter"),
                    Status = const(Open),
                    "Due Date" = field("Urgent Date Filter")
                ));
        }

        // ---------------------------------------------------------
        // Мої заявки
        // ---------------------------------------------------------

        field(40; "My Draft Requests Count"; Integer)
        {
            Caption = 'Чернетки';
            FieldClass = FlowField;
            CalcFormula = count("SI Request Header"
                where(
                    "Requester User ID" = field("User ID Filter"),
                    Status = const(Draft)
                ));
        }

        field(50; "My Pending Requests Count"; Integer)
        {
            Caption = 'На погодженні';
            FieldClass = FlowField;
            CalcFormula = count("SI Request Header"
                where(
                    "Requester User ID" = field("User ID Filter"),
                    Status = const("Pending Approval")
                ));
        }

        field(60; "My Returned Requests Count"; Integer)
        {
            Caption = 'Повернено на доопрацювання';
            FieldClass = FlowField;
            CalcFormula = count("SI Request Header"
                where(
                    "Requester User ID" = field("User ID Filter"),
                    Status = const(Returned)
                ));
        }

        field(70; "Unread Request Notif. Count"; Integer)
        {
            Caption = 'Непрочитані сповіщення';
            FieldClass = FlowField;

            CalcFormula =
                count("SI Notification Entry"
                    where(
                        "Recipient Security ID" =
                            field("Recipient Security ID Filter"),
                        Status =
                            const(Unread),
                        "Source Table ID" =
                            const(52005),
                        "Event Code" =
                            field("Requester Notif. Event Filter")
                    ));
        }

        field(80; "Unread Approver Notif. Count"; Integer)
        {
            Caption = 'Непрочитані сповіщення';
            FieldClass = FlowField;

            CalcFormula =
                count("SI Notification Entry"
                    where(
                        "Recipient Security ID" =
                            field("Recipient Security ID Filter"),
                        Status =
                            const(Unread),
                        "Source Table ID" =
                            const(52005),
                        "Event Code" =
                            field("Approver Notif. Event Filter")
                    ));
        }

        // ---------------------------------------------------------
        // FlowFilters
        // ---------------------------------------------------------
        field(100; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }

        field(110; "Today DateTime Filter"; DateTime)
        {
            Caption = 'Today DateTime Filter';
            FieldClass = FlowFilter;
        }

        field(120; "Urgent Date Filter"; Date)
        {
            Caption = 'Urgent Date Filter';
            FieldClass = FlowFilter;
        }

        field(130; "Recipient Security ID Filter"; Guid)
        {
            Caption = 'Recipient Security ID Filter';
            FieldClass = FlowFilter;
        }

        field(140; "Requester Notif. Event Filter"; Code[50])
        {
            Caption = 'Requester Notification Event Filter';
            FieldClass = FlowFilter;
        }

        field(150; "Approver Notif. Event Filter"; Code[50])
        {
            Caption = 'Approver Notification Event Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}