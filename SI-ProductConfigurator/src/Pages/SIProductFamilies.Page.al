page 53000 "SI Product Families"
{
    PageType = List;
    SourceTable = "SI Product Family";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Сімейства продуктів';
    CardPageId = "SI Product Family Card";

    layout
    {
        area(Content)
        {
            repeater(Families)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стабільний код сімейства продуктів.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву сімейства продуктів.';
                }

                field("Family Template Code"; Rec."Family Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає шаблон параметрів, пов’язаний із сімейством.';
                }

                field("Name Prefix"; Rec."Name Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає текст, з якого починається згенерована назва продукту.';
                }

                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стандартну категорію товару Business Central.';
                }

                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає базову одиницю виміру для товарів цього сімейства.';
                }

                field("Supports Recipes"; Rec."Supports Recipes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи підтримує сімейство виробничі рецептури.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання сімейства.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення сімейств.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
                ToolTip = 'Відкриває параметри, налаштовані для вибраного сімейства.';

                trigger OnAction()
                var
                    FamilyParameter: Record "SI Family Parameter";
                begin
                    Rec.TestField(Code);

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