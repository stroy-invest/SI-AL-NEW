table 61032 "SI Supply Req Site Choice"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy site-selection state. Runtime uses SI Supply Request Site only.';
    Caption = 'Вибір майданчика заявки';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = '№ заявки';
            TableRelation = "SI Supply Req Header"."No.";
        }
        field(2; "Site Code"; Code[20])
        {
            Caption = 'Код майданчика';
        }
        field(3; "Site Name"; Text[100])
        {
            Caption = 'Будівельний майданчик';
            Editable = false;
        }
        field(4; Selected; Boolean)
        {
            Caption = 'Вибрати';
        }
        field(5; "Project No."; Code[20])
        {
            Caption = '№ проєкту';
        }
        field(6; Default; Boolean)
        {
            Caption = 'Основний';
        }
        field(7; Confirmed; Boolean)
        {
            Caption = 'Підтверджено';
        }
    }

    keys
    {
        key(PK; "Request No.", "Site Code") { Clustered = true; }
        key(Project; "Request No.", "Project No.", Selected) { }
    }
}
