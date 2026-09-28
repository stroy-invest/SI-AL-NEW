page 58001 "SI Item Packages"
{
    PageType = List;
    SourceTable = "SI Item Package";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Паковання товарів';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає товар, для якого налаштовано паковання.';
                }
                field("Package Type Code"; Rec."Package Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Виберіть фізичний тип паковання з довідника типів паковань.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає варіант товару, для якого налаштовано паковання.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає фізичну кількість товару в одному пакованні.';
                }
                field("UoM Code"; Rec."UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає одиницю вимірювання фізичної кількості в пакованні.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemPackageMgt: Codeunit "SI Item Package Mgt.";
                    begin
                        if not ItemPackageMgt.LookupCompatibleUoM(Rec) then
                            exit(false);

                        Text := Rec."UoM Code";
                        CurrPage.Update(false);
                        exit(true);
                    end;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Показує автоматично сформований бізнес-код паковання.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис паковання.';
                }
                field("Item UoM Code"; Rec."Item UoM Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Показує автоматично сформований код стандартної Item Unit of Measure для одного паковання.';
                }
                field("Quantity per Package"; Rec."Quantity per Package")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує стандартний коефіцієнт BC: кількість базових одиниць товару в одній одиниці паковання.';
                }
                field("Base UoM Code"; Rec."Base UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує базову одиницю вимірювання товару.';
                }
                field("Default Purchase"; Rec."Default Purchase")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає паковання за замовчуванням для закупівлі.';
                }
                field("Default Sales"; Rec."Default Sales")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає паковання за замовчуванням для продажу.';
                }
                field("Default Warehouse"; Rec."Default Warehouse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає паковання за замовчуванням для складських операцій.';
                }
                field("External Code"; Rec."External Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає зовнішній код паковання для інтеграцій.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Не використовується';
                    ToolTip = 'Визначає, що паковання більше не використовується в нових операціях.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidatePackage)
            {
                ApplicationArea = All;
                Caption = 'Перевірити паковання';
                Image = Check;
                ToolTip = 'Перевіряє паковання та синхронізує стандартну Item Unit of Measure.';

                trigger OnAction()
                var
                    ItemPackageMgt: Codeunit "SI Item Package Mgt.";
                begin
                    ItemPackageMgt.ValidateItemPackage(Rec);
                    CurrPage.Update(false);
                    Message('Паковання перевірено, стандартну одиницю вимірювання товару синхронізовано.');
                end;
            }
        }
    }
}
