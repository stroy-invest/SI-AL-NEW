table 52018 "SI Requester Setup"
{
    Caption = 'Налаштування заявників';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'Користувач';
            TableRelation = "User Setup"."User ID";
        }

        field(10; "Employee No."; Code[20])
        {
            Caption = 'Співробітник';
            TableRelation = Employee."No.";
        }

        field(20; "Construction Object No."; Code[20])
        {
            Caption = 'Об''єкт будівництва';
            TableRelation = "SI Construction Object"."No.";
        }

        field(30; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }
}
