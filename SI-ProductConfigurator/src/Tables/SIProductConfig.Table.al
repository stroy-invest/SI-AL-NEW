table 53004 "SI Product Config."
{
    Caption = 'Конфігурація продукту';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Product Configs.";
    LookupPageId = "SI Product Configs.";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Номер';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                NormalizeNo();
            end;
        }

        field(2; "Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Family".Code;

            trigger OnValidate()
            var
                ProductFamily: Record "SI Product Family";
                ProductConfigValue: Record "SI Product Config. Value";
            begin
                if "Family Code" = '' then
                    exit;

                ProductFamily.Get("Family Code");

                if ProductFamily.Blocked then
                    Error(
                        BlockedFamilyErr,
                        ProductFamily.Code);

                if xRec."Family Code" = "Family Code" then
                    exit;

                ProductConfigValue.SetRange(
                    "Configuration No.",
                    "No.");

                if not ProductConfigValue.IsEmpty() then
                    Error(
                        FamilyChangeWithValuesErr,
                        "No.");

                Clear("Base Item No.");
                ClearGeneratedFields();
            end;
        }

        field(10; Description; Text[2048])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(20; "Short Description"; Text[100])
        {
            Caption = 'Коротка назва';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Composite Key"; Text[2048])
        {
            Caption = 'Composite Key';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(40; "Composite Key Hash"; Text[64])
        {
            Caption = 'Hash Composite Key';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "Search Text"; Text[2048])
        {
            Caption = 'Пошукове представлення';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(60; Status; Enum "SI Product Config. Status")
        {
            Caption = 'Статус';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }

        field(80; "Approved By"; Code[50])
        {
            Caption = 'Затвердив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(90; "Approved At"; DateTime)
        {
            Caption = 'Дата й час затвердження';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(100; "Validation Message"; Text[250])
        {
            Caption = 'Результат перевірки';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(105; "Include Base Name"; Boolean)
        {
            Caption = 'Додати назву категорії/товару до назви конфігурації';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                if xRec."Include Base Name" = "Include Base Name" then
                    exit;

                ClearGeneratedFields();
            end;
        }

        field(106; "Compact Description Parts"; Boolean)
        {
            Caption = 'Прибрати пробіли між частинами назви';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if xRec."Compact Description Parts" = "Compact Description Parts" then
                    exit;

                ClearGeneratedFields();
            end;
        }

        field(110; "Base Item No."; Code[20])
        {
            Caption = 'Базовий товар';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                ProductFamily: Record "SI Product Family";
                Item: Record Item;
            begin
                if "Base Item No." = '' then begin
                    ClearGeneratedFields();
                    exit;
                end;

                TestField("Family Code");
                ProductFamily.Get("Family Code");
                Item.Get("Base Item No.");

                if Item.Blocked then
                    Error(BaseItemBlockedErr, Item."No.");

                if ProductFamily."Item Category Code" = '' then
                    Error(FamilyCategoryRequiredErr, ProductFamily.Code);

                if Item."Item Category Code" <> ProductFamily."Item Category Code" then
                    Error(
                        BaseItemCategoryMismatchErr,
                        Item."No.",
                        Item."Item Category Code",
                        ProductFamily."Item Category Code");

                ClearGeneratedFields();
            end;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }

        key(Family; "Family Code", Status, "No.")
        {
        }

        key(CompositeHash; "Composite Key Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "No.",
            Description,
            "Family Code",
            Status)
        {
        }

        fieldgroup(Brick;
        "No.",
            Description,
            Status)
        {
        }
    }

    trigger OnInsert()
    begin
        NormalizeNo();
        Status := Status::Draft;
    end;

    trigger OnModify()
    begin
        NormalizeNo();
        CheckModificationAllowed();
    end;

    trigger OnDelete()
    begin
        CheckDeleteAllowed();
    end;

    internal procedure SetGeneratedValues(
        NewDescription: Text[100];
        NewShortDescription: Text[100];
        NewCompositeKey: Text[2048];
        NewCompositeKeyHash: Text[64];
        NewSearchText: Text[2048])
    begin
        Description := NewDescription;
        "Short Description" := NewShortDescription;
        "Composite Key" := NewCompositeKey;
        "Composite Key Hash" := NewCompositeKeyHash;
        "Search Text" := NewSearchText;
    end;

    internal procedure SetValidationResult(
        NewStatus: Enum "SI Product Config. Status";
        NewValidationMessage: Text[250])
    begin
        Status := NewStatus;
        "Validation Message" := NewValidationMessage;
    end;

    internal procedure SetApproved()
    begin
        Status := Status::Approved;
        "Approved By" := CopyStr(UserId(), 1, MaxStrLen("Approved By"));
        "Approved At" := CurrentDateTime();
    end;

    internal procedure SetProjected()
    begin
        Status := Status::Projected;
    end;

    local procedure NormalizeNo()
    begin
        "No." := UpperCase(DelChr("No.", '=', ' '));
    end;

    local procedure ClearGeneratedFields()
    begin
        Clear(Description);
        Clear("Short Description");
        Clear("Composite Key");
        Clear("Composite Key Hash");
        Clear("Search Text");
        Clear("Validation Message");

        if Status <> Status::Draft then
            Status := Status::Draft;

        Clear("Approved By");
        Clear("Approved At");
    end;

    local procedure CheckModificationAllowed()
    begin
        if xRec.Status = Status::Archived then
            Error(ArchivedModifyErr, "No.");

        if (xRec.Status = Status::Projected) and
           (xRec."Family Code" <> "Family Code")
        then
            Error(ProjectedFamilyChangeErr, "No.");
    end;

    local procedure CheckDeleteAllowed()
    begin
        if Status in [
            Status::Approved,
            Status::Projected,
            Status::Archived]
        then
            Error(
                DeleteNotAllowedErr,
                "No.",
                Format(Status));
    end;

    var
        BlockedFamilyErr: Label
            'Не можна використовувати заблоковане сімейство %1.';

        ArchivedModifyErr: Label
            'Архівовану конфігурацію %1 не можна змінювати.';

        ProjectedFamilyChangeErr: Label
            'Не можна змінити сімейство конфігурації %1, оскільки для неї вже створено ERP-проєкцію.';

        DeleteNotAllowedErr: Label
            'Не можна видалити конфігурацію %1 зі статусом «%2».';

        FamilyChangeWithValuesErr: Label
            'Не можна змінити сімейство конфігурації %1, оскільки для неї вже задано значення параметрів.';

        BaseItemBlockedErr: Label
            'Базовий товар %1 заблокований і не може використовуватися для створення варіанта.';

        FamilyCategoryRequiredErr: Label
            'Для сімейства %1 не визначено категорію товару Business Central.';

        BaseItemCategoryMismatchErr: Label
            'Товар %1 належить до категорії %2, але сімейство налаштовано для категорії %3.';
}