page 53001 "SI Product Family Card"
{
    PageType = Card;
    SourceTable = "SI Product Family";
    ApplicationArea = All;
    Caption = 'Сімейство продуктів';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільний код сімейства продуктів.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає назву сімейства продуктів.';
                }

                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає англійську назву сімейства продуктів.';
                }

                field("Family Template Code"; Rec."Family Template Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає reusable шаблон параметрів, який можна застосувати до сімейства.';
                }

                field("Name Prefix"; Rec."Name Prefix")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає текст, з якого починається згенерована назва продукту.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення сімейства.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання сімейства.';
                }
            }

            group(ERPSetup)
            {
                Caption = 'Налаштування Business Central';

                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стандартну категорію товару для ERP-проєкції.';
                }

                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає базову одиницю виміру для створюваних товарів.';
                }

                field("Item Template Code"; Rec."Item Template Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Importance = Promoted;
                    ToolTip = 'Визначає обов’язковий шаблон створюваного товару. Якщо шаблону немає, створіть його перед завершенням налаштування сімейства.';
                }

                field("Item Code Prefix"; Rec."Item Code Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стабільний префікс коду товару, наприклад CON.';
                }

                field("Variant Code Prefix"; Rec."Variant Code Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає необов’язковий префікс коду варіанта.';
                }
            }

            group(Production)
            {
                Caption = 'Виробництво';

                field("Supports Recipes"; Rec."Supports Recipes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи можуть продукти цього сімейства мати рецептури.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyFamilyTemplate)
            {
                ApplicationArea = All;
                Caption = 'Застосувати шаблон';
                Image = Apply;
                ToolTip = 'Додає до сімейства відсутні параметри з вибраного шаблону. Наявні параметри не змінюються.';

                trigger OnAction()
                var
                    FamilyTemplateMgt: Codeunit "SI Family Template Mgt.";
                begin
                    Rec.TestField(Code);
                    Rec.TestField("Family Template Code");
                    FamilyTemplateMgt.ApplyTemplate(Rec.Code);
                    CurrPage.Update(false);
                end;
            }

            action(CloneFamily)
            {
                ApplicationArea = All;
                Caption = 'Клонувати сімейство';
                Image = Copy;
                ToolTip = 'Створює нове сімейство як копію налаштувань і параметрів поточного сімейства. Конфігурації, ERP-проєкції та матеріалізація не копіюються.';

                trigger OnAction()
                var
                    CloneDialog: Page "SI Product Family Clone";
                    CloneMgt: Codeunit "SI Product Family Clone Mgt.";
                    ClonedFamily: Record "SI Product Family";
                    NewFamilyCode: Code[30];
                begin
                    Rec.TestField(Code);

                    CloneDialog.SetSourceFamily(Rec);
                    if CloneDialog.RunModal() <> Action::OK then
                        exit;

                    NewFamilyCode := CloneMgt.CloneFamily(
                        Rec.Code,
                        CloneDialog.GetNewFamilyCode(),
                        CloneDialog.GetNewDescription());

                    ClonedFamily.Get(NewFamilyCode);
                    if Confirm(OpenClonedFamilyQst, true, NewFamilyCode) then
                        Page.Run(Page::"SI Product Family Card", ClonedFamily);
                end;
            }

            action(Parameters)
            {
                ApplicationArea = All;
                Caption = 'Параметри сімейства';
                Image = Setup;
                ToolTip = 'Відкриває параметри, налаштовані для цього сімейства.';

                trigger OnAction()
                var
                    FamilyParameter: Record "SI Family Parameter";
                    ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
                begin
                    Rec.TestField(Code);

                    if not ProductConfigMgt.EnsureFamilyItemTemplate(Rec.Code) then
                        exit;

                    // Refresh because guided recovery may have updated Item Template Code.
                    Rec.Get(Rec.Code);
                    Rec.ValidateSetup();

                    FamilyParameter.SetRange(
                        "Family Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Family Parameters",
                        FamilyParameter);
                end;
            }
        }

        area(Promoted)
        {
            actionref(ApplyFamilyTemplatePromoted; ApplyFamilyTemplate)
            {
            }

            actionref(CloneFamilyPromoted; CloneFamily)
            {
            }

            actionref(ParametersPromoted; Parameters)
            {
            }
        }
    }

    var
        OpenClonedFamilyQst: Label 'Сімейство %1 створено. Відкрити його?';

}