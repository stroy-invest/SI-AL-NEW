table 61030 "SI Supply Request Site"
{
    Caption = 'Будівельний майданчик заявки';
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
    }

    keys
    {
        key(PK; "Request No.", "Site Code") { Clustered = true; }
        key(RequestSelected; "Request No.", Selected) { }
    }

    trigger OnInsert()
    begin
        TestRequestEditable();
    end;

    trigger OnModify()
    begin
        TestRequestEditable();
    end;

    trigger OnDelete()
    begin
        TestRequestEditable();
    end;

    local procedure TestRequestEditable()
    var
        Header: Record "SI Supply Req Header";
    begin
        if ("Request No." <> '') and Header.Get("Request No.") then
            Header.TestEditable();
    end;

}
