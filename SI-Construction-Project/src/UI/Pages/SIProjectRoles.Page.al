page 60013 "SI Project Roles"
{
    PageType = List;
    SourceTable = "SI Project Role";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Ролі проєкту та вимоги до працівників';
    AdditionalSearchTerms = 'ролі проєкту,компетенції workforce,керівник проєкту,виконроб';

    layout
    {
        area(Content)
        {
            repeater(Roles)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код ролі';
                    ToolTip = 'Внутрішній стабільний код бізнес-ролі у будівельному проєкті. Код ролі не є кодом посади IW і не зобов’язаний збігатися з кодом Workforce-компетенції.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва ролі';
                    ToolTip = 'Назва функції, яку працівник виконує у конкретному будівельному проєкті або на його майданчику.';
                }
                field(Purpose; Rec.Purpose)
                {
                    ApplicationArea = All;
                    Caption = 'Функція в системі';
                    ToolTip = 'Позначає спеціальне системне призначення ролі. "Керівник проєкту" використовується для відображення керівника проєкту; "Виконроб" — для призначень на будівельних майданчиках. Для інших ролей виберіть "Загальна".';
                }
                field("Assignment Scope"; Rec."Assignment Scope")
                {
                    ApplicationArea = All;
                    Caption = 'Рівень призначення';
                    ToolTip = 'Визначає, чи призначення цієї ролі виконується на рівні всього проєкту або окремого будівельного майданчика.';
                }
                field("Assignment Cardinality"; Rec."Assignment Cardinality")
                {
                    ApplicationArea = All;
                    Caption = 'Допустима кількість';
                    ToolTip = 'Визначає, чи може роль одночасно мати одного або декількох працівників.';
                }
                field("Required Capability Code"; Rec."Required Capability Code")
                {
                    ApplicationArea = All;
                    Caption = 'Необхідна компетенція';
                    ToolTip = 'Workforce-компетенція, яку працівник повинен мати на дату призначення. Компетенція визначається Foundation Workforce, а SI IW HR Adapter надає її працівнику на підставі фактичної посади в IW HR.';
                }
                field("Capability Description"; Rec."Capability Description")
                {
                    ApplicationArea = All;
                    Caption = 'Назва компетенції';
                    ToolTip = 'Назва вибраної Workforce-компетенції.';
                }
                field("Require Primary"; Rec."Require Primary")
                {
                    ApplicationArea = All;
                    Caption = 'Потрібен основний';
                    ToolTip = 'Визначає, чи для цієї ролі має бути позначений основний працівник.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    Caption = 'Активна';
                    ToolTip = 'Неактивні ролі не можна використовувати для нових призначень.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = RecordLinks; }
            systempart(Notes; Notes) { ApplicationArea = Notes; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCapabilities)
            {
                ApplicationArea = All;
                Caption = 'Компетенції Workforce';
                ToolTip = 'Відкриває нейтральний довідник Workforce-компетенцій Foundation. Тут визначається, які компетенції можуть вимагатися ролями проєкту.';
                RunObject = page "SI Workforce Capabilities";
            }
            action(ValidateSetup)
            {
                ApplicationArea = All;
                Caption = 'Перевірити налаштування';
                ToolTip = 'Перевіряє, що спеціальні ролі налаштовані однозначно та кожна активна роль має Workforce-компетенцію.';

                trigger OnAction()
                var
                    Role: Record "SI Project Role";
                    AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
                begin
                    AssignmentMgt.RequireRoleByPurpose("SI Project Role Purpose"::ProjectManager, Role);
                    Role.TestField("Required Capability Code");
                    if Role."Assignment Scope" <> Role."Assignment Scope"::Project then
                        Error('Роль із системним призначенням "Керівник проєкту" повинна мати рівень призначення "Проєкт".');
                    if Role."Assignment Cardinality" <> Role."Assignment Cardinality"::Single then
                        Error('Роль із системним призначенням "Керівник проєкту" повинна мати кратність "Один".');

                    AssignmentMgt.RequireRoleByPurpose("SI Project Role Purpose"::SiteSupervisor, Role);
                    Role.TestField("Required Capability Code");
                    if Role."Assignment Scope" <> Role."Assignment Scope"::Site then
                        Error('Роль із системним призначенням "Виконроб" повинна мати рівень призначення "Будівельний майданчик".');

                    Role.Reset();
                    Role.SetRange(Active, true);
                    if Role.FindSet() then
                        repeat
                            Role.TestField("Required Capability Code");
                        until Role.Next() = 0;

                    Message('Налаштування ролей і Workforce-компетенцій коректне.');
                end;
            }
        }
        area(Promoted)
        {
            actionref(ValidateSetupPromoted; ValidateSetup) { }
            actionref(OpenCapabilitiesPromoted; OpenCapabilities) { }
        }
    }
}
