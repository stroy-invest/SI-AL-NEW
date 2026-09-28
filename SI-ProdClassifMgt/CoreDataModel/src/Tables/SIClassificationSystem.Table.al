table 56000 "SI Classification System"
{
    Caption = 'Система класифікації';
    DataClassification = CustomerContent;
    DataCaptionFields = Code, Description;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва';
        }
        field(3; "Description EN"; Text[100])
        {
            Caption = 'Назва англійською';
        }
        field(4; Authority; Text[100])
        {
            Caption = 'Орган, що веде класифікатор';
        }
        field(5; Version; Text[30])
        {
            Caption = 'Версія';
        }
        field(6; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            TableRelation = "Country/Region".Code;
        }
        field(7; "Is Hierarchical"; Boolean)
        {
            Caption = 'Ієрархічна система';
            InitValue = true;
        }
        field(8; "Is Active"; Boolean)
        {
            Caption = 'Активна';
            InitValue = true;
        }
        field(9; "Default for Reporting"; Boolean)
        {
            Caption = 'За замовчуванням для звітності';
        }
        field(10; "Valid From"; Date)
        {
            Caption = 'Чинна з';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(11; "Valid To"; Date)
        {
            Caption = 'Чинна до';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(12; "Source URL"; Text[250])
        {
            Caption = 'URL джерела';
            ExtendedDatatype = URL;
        }
        field(13; "Source Description"; Text[250])
        {
            Caption = 'Опис джерела';
        }
        field(14; "Last Import DateTime"; DateTime)
        {
            Caption = 'Дата й час останнього імпорту';
            Editable = false;
        }
        field(15; "Last Import User ID"; Code[50])
        {
            Caption = 'Користувач останнього імпорту';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Entry Count"; Integer)
        {
            Caption = 'Кількість вузлів';
            FieldClass = FlowField;
            CalcFormula = count("SI Classification Node" where(
                "Classification System Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(DescriptionKey; Description)
        {
        }
        key(ActiveKey; "Is Active", Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, Version)
        {
        }
        fieldgroup(Brick; Code, Description, Version)
        {
        }
    }

    trigger OnDelete()
    var
        ClassificationNode: Record "SI Classification Node";
    begin
        ClassificationNode.SetRange("Classification System Code", Code);
        if not ClassificationNode.IsEmpty() then
            Error(
                SystemHasNodesErr,
                Code);
    end;

    trigger OnRename()
    var
        ClassificationNode: Record "SI Classification Node";
    begin
        ClassificationNode.SetRange("Classification System Code", xRec.Code);
        if not ClassificationNode.IsEmpty() then
            Error(
                SystemHasNodesRenameErr,
                xRec.Code);
    end;

    local procedure ValidateValidityPeriod()
    begin
        if ("Valid From" <> 0D) and
           ("Valid To" <> 0D) and
           ("Valid To" < "Valid From")
        then
            Error(InvalidValidityPeriodErr);
    end;

    var
        InvalidValidityPeriodErr: Label 'Дата «Діє до» не може бути ранішою за дату «Діє з».';
        SystemHasNodesErr: Label 'Систему класифікації %1 не можна видалити, оскільки вона містить вузли.';
        SystemHasNodesRenameErr: Label 'Код системи класифікації %1 не можна змінити, оскільки система містить вузли.';
}
