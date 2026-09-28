page 53024 "SI ERP Projection Preview"
{
    PageType = StandardDialog;
    SourceTable = "SI ERP Projection Prev Buffer";
    SourceTableTemporary = true;

    Caption = 'Попередній перегляд ERP-проєкції';

    layout
    {
        area(Content)
        {
            group(ProductContext)
            {
                Caption = 'Контекст продукту';

                field("Configuration No."; Rec."Configuration No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує конфігурацію продукту, для якої побудовано попередній перегляд.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує сімейство продукту.';
                }

                field("Family Description"; Rec."Family Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує назву сімейства продукту.';
                }

                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує категорію товару Business Central.';
                }

                field(
                    "Item Category Description";
                Rec."Item Category Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує назву категорії товару.';
                }

                field("Item Template Code"; Rec."Item Template Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує шаблон товару Business Central.';
                }

                field(
                    "Item Template Description";
                Rec."Item Template Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує назву шаблону товару.';
                }
            }

            group(ItemProjection)
            {
                Caption = 'Проєкція товару';

                field(
                    "Item Projection Key";
                Rec."Item Projection Key")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Вказує технічний ключ проєкції товару.';
                }

                field(
                    "Generated Item Code";
                Rec."Generated Item Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує запланований код стандартного товару Business Central.';
                }

                field(
                    "Generated Item Description";
                Rec."Generated Item Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує заплановану назву стандартного товару Business Central.';
                }

                field(
                    "Existing Item No.";
                Rec."Existing Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує вже наявний товар Business Central для цієї проєкції.';
                }

                field(
                    "Existing Item Prj. Entry No.";
                Rec."Existing Item Prj. Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує наявний запис корпоративної проєкції товару.';
                }
            }

            group(VariantProjection)
            {
                Caption = 'Проєкція варіанта';

                field(
                    "Generated Variant Code";
                Rec."Generated Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує запланований код варіанта товару.';
                }

                field(
                    "Generated Variant Description";
                Rec."Generated Variant Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує заплановану назву варіанта товару.';
                }

                field(
                    "Existing Variant Code";
                Rec."Existing Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує вже наявний варіант товару Business Central.';
                }
            }

            group(UnitOfMeasure)
            {
                Caption = 'Одиниця виміру';

                field("Base UoM Code"; Rec."Base UoM Code")
                {
                    ApplicationArea = All;
                    Editable = ManualUoMEditable;
                    Importance = Promoted;
                    ToolTip = 'Вказує базову одиницю виміру майбутнього товару. Ручний вибір доступний, якщо одиницю не визначено категорією або шаблоном.';

                    trigger OnValidate()
                    var
                        ProjectionValidator: Codeunit "SI ERP Projection Validator";
                    begin
                        Rec.SetManualBaseUoM(
                            Rec."Base UoM Code");

                        ProjectionValidator.ValidatePreview(Rec);

                        UpdatePageState();
                        CurrPage.Update(false);
                    end;
                }

                field("Base UoM Source"; Rec."Base UoM Source")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Вказує джерело визначення базової одиниці виміру.';
                }
            }

            group(Readiness)
            {
                Caption = 'Готовність';

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує стан готовності ERP-проєкції.';
                }

                field("Is Ready"; Rec."Is Ready")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Вказує, чи готова проєкція до матеріалізації.';
                }

                field(
                    "Validation Message";
                Rec."Validation Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Показує результат перевірки ERP-проєкції.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePageState();
    end;

    procedure SetPreviewBuffer(
        var TempBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    begin
        Rec.Copy(
            TempBuffer,
            true);

        if Rec.FindFirst() then;
    end;

    local procedure UpdatePageState()
    begin
        ManualUoMEditable :=
            Rec."Base UoM Source" in [
                Rec."Base UoM Source"::None,
                Rec."Base UoM Source"::Manual];
    end;

    var
        ManualUoMEditable: Boolean;
}