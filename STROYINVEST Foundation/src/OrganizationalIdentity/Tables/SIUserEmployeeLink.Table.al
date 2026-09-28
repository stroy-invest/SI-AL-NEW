table 50600 "SI User Employee Link"
{
    Caption = 'Зв''язок користувача і працівника';
    DataClassification = CustomerContent;
    DataPerCompany = true;
    LookupPageId = "SI User Employee Links";
    DrillDownPageId = "SI User Employee Links";

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'Ідентифікатор користувача';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            var
                UserRecord: Record User;
            begin
                if IsNullGuid("User Security ID") then
                    exit;

                if not UserRecord.Get("User Security ID") then
                    Error(UserNotFoundErr, "User Security ID");
            end;
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = '№ працівника';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";

            trigger OnValidate()
            var
                UserEmployeeLink: Record "SI User Employee Link";
            begin
                if "Employee No." = '' then
                    exit;

                UserEmployeeLink.SetRange("Employee No.", "Employee No.");
                if not IsNullGuid("User Security ID") then
                    UserEmployeeLink.SetFilter("User Security ID", '<>%1', "User Security ID");

                if UserEmployeeLink.FindFirst() then
                    Error(
                        EmployeeAlreadyLinkedErr,
                        "Employee No.",
                        UserEmployeeLink."User Security ID");
            end;
        }
    }

    keys
    {
        key(PK; "User Security ID")
        {
            Clustered = true;
        }
        key(Employee; "Employee No.")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateLink();
    end;

    trigger OnModify()
    begin
        ValidateLink();
    end;

    local procedure ValidateLink()
    begin
        if IsNullGuid("User Security ID") then
            Error(UserRequiredErr);

        TestField("Employee No.");
        Validate("User Security ID");
        Validate("Employee No.");
    end;

    var
        UserNotFoundErr: Label 'Користувача з ідентифікатором %1 не знайдено.', Comment = '%1 = User Security ID';
        UserRequiredErr: Label 'Необхідно вибрати користувача Business Central.';
        EmployeeAlreadyLinkedErr: Label 'Працівник %1 уже пов''язаний з іншим користувачем (%2). Один працівник може мати лише один зв''язок з користувачем у межах компанії.', Comment = '%1 = Employee No., %2 = User Security ID';
}
