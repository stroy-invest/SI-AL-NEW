table 56001 "SI Classification Node"
{
    Caption = 'Вузол класифікації';
    DataClassification = CustomerContent;
    DataCaptionFields = "Classification System Code", Code, Description;

    fields
    {
        field(1; "Classification System Code"; Code[20])
        {
            Caption = 'Код системи класифікації';
            NotBlank = true;
            TableRelation = "SI Classification System".Code;

            trigger OnValidate()
            begin
                if "Classification System Code" = xRec."Classification System Code" then
                    exit;

                if xRec."Classification System Code" <> '' then
                    Error(SystemCodeChangeErr);

                ValidateParentHierarchy();
                UpdateDerivedHierarchyFields();
            end;
        }
        field(2; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Назва';

            trigger OnValidate()
            begin
                if "Search Description" = '' then
                    "Search Description" := CopyStr(Description, 1, MaxStrLen("Search Description"));
            end;
        }
        field(4; "Description EN"; Text[250])
        {
            Caption = 'Назва англійською';
        }
        field(5; "Parent Code"; Code[50])
        {
            Caption = 'Код батьківського вузла';
            TableRelation = "SI Classification Node".Code where(
                "Classification System Code" = field("Classification System Code"));

            trigger OnValidate()
            begin
                ValidateParentHierarchy();
                UpdateDerivedHierarchyFields();
            end;
        }
        field(6; Level; Integer)
        {
            Caption = 'Рівень';
            MinValue = 0;
            Editable = false;
        }
        field(7; "Node Type"; Enum "SI Classification Node Type")
        {
            Caption = 'Тип вузла';
        }
        field(8; "Sort Order"; Integer)
        {
            Caption = 'Порядок сортування';
        }
        field(9; "Is Leaf"; Boolean)
        {
            Caption = 'Кінцевий вузол';
            InitValue = true;
            Editable = false;
        }
        field(10; "Is Selectable"; Boolean)
        {
            Caption = 'Доступний для вибору';
            InitValue = true;
        }
        field(11; "Is Service"; Boolean)
        {
            Caption = 'Послуга';
        }
        field(12; "Is Active"; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }
        field(13; "Valid From"; Date)
        {
            Caption = 'Діє з';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(14; "Valid To"; Date)
        {
            Caption = 'Діє до';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(15; "Search Description"; Text[250])
        {
            Caption = 'Назва для пошуку';
        }
        field(16; "Full Path"; Text[2048])
        {
            Caption = 'Повний шлях';
            Editable = false;
        }
        field(17; "Source Version"; Text[30])
        {
            Caption = 'Версія джерела';
        }
        field(18; "Source Line No."; Integer)
        {
            Caption = 'Номер рядка джерела';
        }
        field(19; "Child Count"; Integer)
        {
            Caption = 'Кількість дочірніх вузлів';
            FieldClass = FlowField;
            CalcFormula = count("SI Classification Node" where(
                "Classification System Code" = field("Classification System Code"),
                "Parent Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Classification System Code", Code)
        {
            Clustered = true;
        }
        key(ParentKey; "Classification System Code", "Parent Code", "Sort Order", Code)
        {
        }
        key(DescriptionKey; "Classification System Code", Description)
        {
        }
        key(SearchKey; "Classification System Code", "Search Description")
        {
        }
        key(ActiveKey; "Classification System Code", "Is Active", "Is Selectable")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Node Type", Level)
        {
        }
        fieldgroup(Brick; Code, Description, "Node Type", Level)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Classification System Code");
        TestField(Code);

        ValidateParentHierarchy();
        UpdateDerivedHierarchyFields();

        "Is Leaf" := true;
        SetParentAsNonLeaf("Parent Code");
    end;

    trigger OnModify()
    begin
        TestField("Classification System Code");
        TestField(Code);

        ValidateParentHierarchy();
        ValidateValidityPeriod();

        if ("Parent Code" <> xRec."Parent Code") or
           ("Classification System Code" <> xRec."Classification System Code")
        then begin
            UpdateDerivedHierarchyFields();

            UpdateOldParentLeafStatus(
                xRec."Classification System Code",
                xRec."Parent Code");

            SetParentAsNonLeaf("Parent Code");
        end;
    end;

    trigger OnDelete()
    var
        ChildNode: Record "SI Classification Node";
    begin
        ChildNode.SetRange("Classification System Code", "Classification System Code");
        ChildNode.SetRange("Parent Code", Code);

        if not ChildNode.IsEmpty() then
            Error(NodeHasChildrenErr, Code);

        UpdateOldParentLeafStatus(
            "Classification System Code",
            "Parent Code");
    end;

    trigger OnRename()
    var
        ChildNode: Record "SI Classification Node";
    begin
        ChildNode.SetRange("Classification System Code", xRec."Classification System Code");
        ChildNode.SetRange("Parent Code", xRec.Code);

        if not ChildNode.IsEmpty() then
            Error(NodeHasChildrenRenameErr, xRec.Code);
    end;

    internal procedure ValidateParentHierarchy()
    var
        ParentNode: Record "SI Classification Node";
        CurrentParentCode: Code[50];
        TraversedNodeCount: Integer;
    begin
        if "Parent Code" = '' then
            exit;

        TestField("Classification System Code");
        TestField(Code);

        if "Parent Code" = Code then
            Error(NodeCannotBeOwnParentErr, Code);

        CurrentParentCode := "Parent Code";

        while CurrentParentCode <> '' do begin
            TraversedNodeCount += 1;

            if TraversedNodeCount > 1000 then
                Error(HierarchyDepthExceededErr);

            if CurrentParentCode = Code then
                Error(CircularHierarchyErr, Code);

            if not ParentNode.Get("Classification System Code", CurrentParentCode) then
                Error(
                    ParentNodeNotFoundErr,
                    CurrentParentCode,
                    "Classification System Code");

            CurrentParentCode := ParentNode."Parent Code";
        end;
    end;

    internal procedure UpdateDerivedHierarchyFields()
    var
        ParentNode: Record "SI Classification Node";
    begin
        if "Parent Code" = '' then begin
            Level := 0;
            "Full Path" := CopyStr(Code, 1, MaxStrLen("Full Path"));
            exit;
        end;

        if not ParentNode.Get("Classification System Code", "Parent Code") then
            exit;

        Level := ParentNode.Level + 1;

        if ParentNode."Full Path" = '' then
            "Full Path" :=
                CopyStr(
                    ParentNode.Code + ' > ' + Code,
                    1,
                    MaxStrLen("Full Path"))
        else
            "Full Path" :=
                CopyStr(
                    ParentNode."Full Path" + ' > ' + Code,
                    1,
                    MaxStrLen("Full Path"));
    end;

    local procedure SetParentAsNonLeaf(ParentCode: Code[50])
    var
        ParentNode: Record "SI Classification Node";
    begin
        if ParentCode = '' then
            exit;

        if not ParentNode.Get("Classification System Code", ParentCode) then
            exit;

        if not ParentNode."Is Leaf" then
            exit;

        ParentNode."Is Leaf" := false;
        ParentNode.Modify(false);
    end;

    local procedure UpdateOldParentLeafStatus(
        ParentSystemCode: Code[20];
        ParentCode: Code[50])
    var
        ParentNode: Record "SI Classification Node";
        OtherChildNode: Record "SI Classification Node";
        ParentIsLeaf: Boolean;
    begin
        if ParentCode = '' then
            exit;

        if not ParentNode.Get(ParentSystemCode, ParentCode) then
            exit;

        OtherChildNode.SetRange("Classification System Code", ParentSystemCode);
        OtherChildNode.SetRange("Parent Code", ParentCode);
        OtherChildNode.SetFilter(Code, '<>%1', Code);

        ParentIsLeaf := OtherChildNode.IsEmpty();

        if ParentNode."Is Leaf" = ParentIsLeaf then
            exit;

        ParentNode."Is Leaf" := ParentIsLeaf;
        ParentNode.Modify(false);
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
        CircularHierarchyErr: Label 'Для вузла %1 виявлено циклічний зв’язок у структурі класифікації.';
        HierarchyDepthExceededErr: Label 'Не вдалося перевірити ієрархію: ланцюжок батьківських вузлів перевищує допустиму глибину.';
        InvalidValidityPeriodErr: Label 'Дата «Діє до» не може бути ранішою за дату «Діє з».';
        NodeCannotBeOwnParentErr: Label 'Вузол %1 не може бути власним батьківським вузлом.';
        NodeHasChildrenErr: Label 'Вузол %1 не можна видалити, оскільки він містить дочірні вузли.';
        NodeHasChildrenRenameErr: Label 'Код вузла %1 не можна змінити, оскільки вузол містить дочірні вузли.';
        ParentNodeNotFoundErr: Label 'Батьківський вузол %1 не існує в системі класифікації %2.';
        SystemCodeChangeErr: Label 'Код системи класифікації не можна змінювати для вже створеного вузла.';
}
