page 58004 "SI Unit of Measure Card"
{
    PageType = Card;
    SourceTable = "Unit of Measure";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Одиниця вимірювання';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні відомості';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код одиниці вимірювання.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис одиниці вимірювання.';
                }
                field("SI Symbol"; Rec."SI Symbol")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає коротке позначення одиниці вимірювання, наприклад кг, м або шт.';
                }
                field("International Standard Code"; Rec."International Standard Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає міжнародний стандартний код одиниці вимірювання.';
                }
                field("SI Measurement System"; Rec."SI Measurement System")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає систему вимірювання, до якої належить одиниця.';
                }
                field("SI UoM Kind"; Rec."SI UoM Kind")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Визначає обов’язковий структурний тип одиниці вимірювання.';

                    trigger OnValidate()
                    begin
                        SetControlState();
                        CurrPage.Update(false);
                    end;
                }
                field("SI Blocked"; Rec."SI Blocked")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, що одиниця вимірювання більше не використовується для нових налаштувань.';
                }
            }

            group(Conversion)
            {
                Caption = 'Перерахунок масштабованої одиниці';

                field("SI Reference UoM Code"; Rec."SI Reference UoM Code")
                {
                    ApplicationArea = All;
                    Editable = IsScaled;
                    ShowMandatory = IsScaled;
                    ToolTip = 'Визначає базову або іншу масштабовану одиницю, до якої перераховується поточна одиниця.';

                    trigger OnValidate()
                    begin
                        SetControlState();
                        CurrPage.Update(false);
                    end;
                }
                field("SI Conversion Factor"; Rec."SI Conversion Factor")
                {
                    ApplicationArea = All;
                    Editable = IsScaled;
                    ShowMandatory = IsScaled;
                    ToolTip = 'Визначає кількість одиниць посилання в одній поточній одиниці.';

                    trigger OnValidate()
                    begin
                        SetControlState();
                        CurrPage.Update(false);
                    end;
                }
                field("SI Conversion Formula"; ConversionFormula)
                {
                    ApplicationArea = All;
                    Caption = 'Формула перерахунку';
                    Editable = false;
                    ToolTip = 'Показує, як поточна одиниця вимірювання перераховується в одиницю посилання.';
                }
            }

            group(DerivedStructure)
            {
                Caption = 'Структура похідної одиниці';
                Visible = IsDerived;

                field("SI Numerator UoM Code"; Rec."SI Numerator UoM Code")
                {
                    ApplicationArea = All;
                    Editable = IsDerived;
                    ShowMandatory = IsDerived;
                    ToolTip = 'Визначає одиницю вимірювання в чисельнику.';
                }
                field("SI Numerator Quantity"; Rec."SI Numerator Quantity")
                {
                    ApplicationArea = All;
                    Editable = IsDerived;
                    ShowMandatory = IsDerived;
                    ToolTip = 'Визначає кількість одиниць чисельника у структурі похідної одиниці, наприклад 1 для л/100 км.';
                }
                field("SI Denominator UoM Code"; Rec."SI Denominator UoM Code")
                {
                    ApplicationArea = All;
                    Editable = IsDerived;
                    ShowMandatory = IsDerived;
                    ToolTip = 'Визначає одиницю вимірювання у знаменнику.';
                }
                field("SI Denominator Quantity"; Rec."SI Denominator Quantity")
                {
                    ApplicationArea = All;
                    Editable = IsDerived;
                    ShowMandatory = IsDerived;
                    ToolTip = 'Визначає кількість одиниць знаменника у структурі похідної одиниці, наприклад 100 для л/100 км.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateStructure)
            {
                ApplicationArea = All;
                Caption = 'Перевірити структуру';
                Image = Check;
                ToolTip = 'Перевіряє правильність налаштування структури одиниці вимірювання.';

                trigger OnAction()
                var
                    SIUoMMgt: Codeunit "SI UoM Mgt.";
                begin
                    SIUoMMgt.ValidateUoM(Rec);
                    Message('Структуру одиниці вимірювання перевірено успішно.');
                end;
            }

            action(TestDerivedCalculation)
            {
                ApplicationArea = All;
                Caption = 'Перевірити розрахунок';
                Image = Calculate;
                ToolTip = 'Відкриває діагностичний калькулятор для перевірки розрахунку поточної похідної одиниці вимірювання.';
                Visible = IsDerived;

                trigger OnAction()
                var
                    DerivedUoMTest: Page "SI Derived UoM Test";
                begin
                    Rec.TestField(Code);
                    DerivedUoMTest.SetDerivedUoMCode(Rec.Code);
                    DerivedUoMTest.RunModal();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetControlState();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetControlState();
    end;

    local procedure SetControlState()
    begin
        IsScaled := Rec."SI UoM Kind" = Rec."SI UoM Kind"::Scaled;
        IsDerived := Rec."SI UoM Kind" = Rec."SI UoM Kind"::Derived;
        ConversionFormula := GetConversionFormula();
    end;

    local procedure GetConversionFormula(): Text[250]
    var
        CurrentSymbol: Text[20];
        ReferenceSymbol: Text[20];
        ReferenceUoM: Record "Unit of Measure";
    begin
        if not IsScaled then
            exit('');

        if (Rec.Code = '') or
           (Rec."SI Reference UoM Code" = '') or
           (Rec."SI Conversion Factor" <= 0)
        then
            exit('');

        CurrentSymbol := Rec."SI Symbol";
        if CurrentSymbol = '' then
            CurrentSymbol := Rec.Code;

        ReferenceSymbol := Rec."SI Reference UoM Code";
        if ReferenceUoM.Get(Rec."SI Reference UoM Code") then
            if ReferenceUoM."SI Symbol" <> '' then
                ReferenceSymbol := ReferenceUoM."SI Symbol";

        exit(StrSubstNo(
            '1 %1 = %2 %3',
            CurrentSymbol,
            Format(Rec."SI Conversion Factor", 0, '<Precision,0:10><Standard Format,0>'),
            ReferenceSymbol));
    end;

    var
        IsScaled: Boolean;
        IsDerived: Boolean;
        ConversionFormula: Text[250];
}
