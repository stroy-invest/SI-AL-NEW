tableextension 60028 "SI ShipTo Employee" extends "Ship-to Address"
{
    fields
    {
        field(60027; "SI Contact Employee No."; Code[20])
        {
            Caption = 'Контактна особа';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";
            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if "SI Contact Employee No." = '' then begin
                    Contact := '';
                    exit;
                end;
                Employee.Get("SI Contact Employee No.");
                Contact := CopyStr(Employee.FullName(), 1, MaxStrLen(Contact));
            end;
        }
    }
}
