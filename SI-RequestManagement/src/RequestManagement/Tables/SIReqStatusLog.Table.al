table 52008 "SI Req. Status Log"
{
    Caption = 'SI Request Status Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(10; "Request No."; Code[20])
        {
            Caption = 'Request No.';
            TableRelation = "SI Request Header"."No.";
        }

        field(20; "Old Status"; Enum "SI Request Status")
        {
            Caption = 'Old Status';
        }

        field(30; "New Status"; Enum "SI Request Status")
        {
            Caption = 'New Status';
        }

        field(40; "Action Code"; Code[30])
        {
            Caption = 'Action Code';
        }

        field(50; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
        }

        field(60; "Date Time"; DateTime)
        {
            Caption = 'Date Time';
        }

        field(70; Comment; Text[250])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(RequestNo; "Request No.", "Date Time")
        {
        }
    }
}