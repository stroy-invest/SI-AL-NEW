table 54030 "SI BP Role"
{
    Caption = 'Ролі контрагента';
    DataClassification = CustomerContent;
    DataCaptionFields = Code, "Business Partner No.", "Role Type";

    fields
    {
        field(1; Code; Code[30])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(2; "Business Partner No."; Code[20])
        {
            Caption = 'Контрагент';
            TableRelation = "SI Business Partner"."No.";
            NotBlank = true;
        }

        field(3; "Role Type"; Enum "SI BP Role Type")
        {
            Caption = 'Тип ролі';
        }

        field(4; Status; Enum "SI BP Role Status")
        {
            Caption = 'Стан';
        }


        field(7; "ERP Template Code"; Code[20])
        {
            Caption = 'Шаблон BC';
            ObsoleteState = Pending;
            ObsoleteReason = 'Standard BC templates are no longer part of SI BP role configuration or materialization.';
        }

        field(6; "Business Partner Name"; Text[250])
        {
            Caption = 'Контрагент';
            FieldClass = FlowField;
            CalcFormula =
                lookup(
                    "SI Business Partner".Name
                    where("No." = field("Business Partner No.")));
            Editable = false;
        }

        field(10; "Customer No."; Code[20])
        {
            Caption = 'Код покупця';
            TableRelation = Customer."No.";
        }

        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Код постачальника';
            TableRelation = Vendor."No.";
        }

        field(20; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }

        field(21; "Created By"; Text[100])
        {
            Caption = 'Створив';
            Editable = false;
        }

        field(22; "Last Changed At"; DateTime)
        {
            Caption = 'Остання зміна';
            Editable = false;
        }

        field(23; "Last Changed By"; Text[100])
        {
            Caption = 'Змінив';
            Editable = false;
        }

        field(30; "Last Activated At"; DateTime)
        {
            Caption = 'Остання активація';
            Editable = false;
        }

        field(31; "Last Inactivated At"; DateTime)
        {
            Caption = 'Остання деактивація';
            Editable = false;
        }

        field(32; "Closed At"; DateTime)
        {
            Caption = 'Закрито';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Closed is a legacy status. Inactive is the terminal state of a role instance.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(BusinessPartnerRole; "Business Partner No.", "Role Type")
        {
        }

        key(StatusKey; Status, "Role Type")
        {
        }
    }

    trigger OnInsert()
    begin
        EnsureUniqueRole();

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;

        if "Created By" = '' then
            "Created By" :=
                CopyStr(UserId(), 1, MaxStrLen("Created By"));

        "Last Changed At" := CurrentDateTime;
        "Last Changed By" :=
            CopyStr(UserId(), 1, MaxStrLen("Last Changed By"));
    end;

    trigger OnModify()
    begin
        EnsureUniqueRole();
    end;

    local procedure EnsureUniqueRole()
    var
        ExistingRole: Record "SI BP Role";
    begin
        if "Business Partner No." = '' then
            exit;

        if Status in [Status::Inactive, Status::Closed] then
            exit;

        ExistingRole.SetRange(
            "Business Partner No.",
            "Business Partner No.");

        ExistingRole.SetRange(
            "Role Type",
            "Role Type");

        ExistingRole.SetFilter(
            Code,
            '<>%1',
            Code);

        ExistingRole.SetFilter(
            Status,
            '<>%1&<>%2',
            ExistingRole.Status::Inactive,
            ExistingRole.Status::Closed);

        if not ExistingRole.IsEmpty() then
            Error(
                'Для контрагента %1 вже існує поточна роль типу %2.',
                "Business Partner No.",
                Format("Role Type"));
    end;
}