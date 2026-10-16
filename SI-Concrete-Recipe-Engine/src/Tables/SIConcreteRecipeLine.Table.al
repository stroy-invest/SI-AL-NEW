namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

table 62022 "SI Concrete Recipe Line"
{
    Caption = 'Рядок рецептури бетону';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Recipe No."; Code[50])
        {
            Caption = 'Код рецептури';
            TableRelation = "SI Concrete Recipe"."Recipe No.";
            ToolTip = 'Вказує рецептуру.';
        }
        field(2; "Revision No."; Integer)
        {
            Caption = '№ ревізії';
            TableRelation = "SI Concrete Recipe Revision"."Revision No." where("Recipe No." = field("Recipe No."));
            ToolTip = 'Вказує ревізію рецептури.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = '№ рядка';
            ToolTip = 'Вказує номер рядка рецептури.';
        }
        field(9; "Material Type Value ID"; Integer)
        {
            Caption = 'Тип матеріалу';
            ToolTip = 'Значення атрибута REC_MAT_TYPE, успадкованого категоріями товарів.';

            trigger OnValidate()
            var
                MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
            begin
                MaterialMgt.ValidateMaterialValue("Material Type Value ID");
                MaterialMgt.ValidateItem("Material Type Value ID", "Item No.");
            end;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Код товару';
            TableRelation = Item."No.";
            ToolTip = 'Вказує товар-компонент, що споживається за цією рецептурою.';

            trigger OnValidate()
            var
                Item: Record Item;
                MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
            begin
                if "Item No." = xRec."Item No." then
                    exit;

                "Variant Code" := '';
                "Unit of Measure Code" := '';
                Description := '';

                MaterialMgt.ValidateItem("Material Type Value ID", "Item No.");
                if Item.Get("Item No.") then begin
                    Description := Item.Description;
                    "Unit of Measure Code" := Item."Base Unit of Measure";
                end;
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Код варіанта';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ToolTip = 'Вказує варіант товару-компонента, за потреби.';

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                Item: Record Item;
            begin
                if "Variant Code" = '' then begin
                    if Item.Get("Item No.") then
                        Description := Item.Description;
                    exit;
                end;

                ItemVariant.Get("Item No.", "Variant Code");
                if ItemVariant.Description <> '' then
                    Description := ItemVariant.Description;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Опис';
            ToolTip = 'Вказує опис компонента.';
        }
        field(20; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Код одиниці виміру';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
            ToolTip = 'Вказує одиницю виміру кількості компонента.';
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            ToolTip = 'Вказує кількість компонента на базис виходу рецептури.';

            trigger OnValidate()
            begin
                if Quantity <= 0 then
                    Error(QuantityPositiveErr);
            end;
        }
    }

    keys
    {
        key(PK; "Recipe No.", "Revision No.", "Line No.")
        {
            Clustered = true;
        }
        key(Component; "Item No.", "Variant Code")
        {
        }
    }

    trigger OnInsert()
    begin
        EnsureDraftRevision();
        ValidateMaterialClassification();
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
    end;

    trigger OnModify()
    begin
        if AllowAdminMaterialModify then begin
            CheckAdminMaterialOnly();
            ValidateMaterialClassification();
            exit;
        end;
        EnsureDraftRevision();
        ValidateMaterialClassification();
    end;

    trigger OnDelete()
    begin
        EnsureDraftRevision();
    end;

    trigger OnRename()
    begin
        EnsureDraftRevision();
    end;

    procedure ApplyAdminMaterialType(NewValueId: Integer)
    var
        AdminAccess: Codeunit "SI Recipe Admin Edit Access";
    begin
        AdminAccess.RequireSuper();
        Validate("Material Type Value ID", NewValueId);
        AllowAdminMaterialModify := true;
        Modify(true);
        AllowAdminMaterialModify := false;
    end;

    local procedure CheckAdminMaterialOnly()
    begin
        if ("Recipe No." <> xRec."Recipe No.") or
           ("Revision No." <> xRec."Revision No.") or
           ("Line No." <> xRec."Line No.") or
           ("Item No." <> xRec."Item No.") or
           ("Variant Code" <> xRec."Variant Code") or
           (Description <> xRec.Description) or
           ("Unit of Measure Code" <> xRec."Unit of Measure Code") or
           (Quantity <> xRec.Quantity) then
            Error(AdminMaterialOnlyErr);
    end;

    procedure ValidateMaterialClassification()
    var
        MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
    begin
        MaterialMgt.ValidateMaterialValue("Material Type Value ID");
        MaterialMgt.ValidateItem("Material Type Value ID", "Item No.");
    end;

    local procedure GetNextLineNo(): Integer
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        RecipeSetup: Record "SI Concrete Recipe Setup";
        LineIncrement: Integer;
    begin
        LineIncrement := 10000;
        if RecipeSetup.Get('') and (RecipeSetup."Default Line Increment" > 0) then
            LineIncrement := RecipeSetup."Default Line Increment";

        RecipeLine.LockTable();
        RecipeLine.SetRange("Recipe No.", "Recipe No.");
        RecipeLine.SetRange("Revision No.", "Revision No.");
        if RecipeLine.FindLast() then
            exit(RecipeLine."Line No." + LineIncrement);
        exit(LineIncrement);
    end;

    local procedure EnsureDraftRevision()
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
    begin
        RecipeRevision.Get("Recipe No.", "Revision No.");
        if RecipeRevision.Status <> RecipeRevision.Status::Draft then
            Error(ControlledRevisionLineErr, "Recipe No.", "Revision No.");
    end;

    var
        AllowAdminMaterialModify: Boolean;
        AdminMaterialOnlyErr: Label 'Адміністративний режим дозволяє змінювати лише тип матеріалу.';
        QuantityPositiveErr: Label 'Кількість має бути більшою за нуль.';
        ControlledRevisionLineErr: Label 'Рядки рецептури %1 ревізії %2 не можна змінювати, оскільки ревізія сертифікована або неактивна.';
}
