page 53002 "SI Product Parameters"
{
    PageType = List;
    SourceTable = "SI Product Parameter";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Параметри продуктів';
    CardPageId = "SI Product Param. Card";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільний корпоративний код параметра.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає назву параметра продукту.';
                }

                field("Base Item Category Code"; Rec."Base Item Category Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає базову категорію товарів, для якої призначений параметр. Порожнє значення означає глобальний параметр.';
                }

                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Визначає англійську назву параметра.';
                }

                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає тип значень, які може приймати параметр.';
                }

                field("SI Semantic Code"; Rec."SI Semantic Code")
                {
                    ApplicationArea = All;
                    Caption = 'Семантика параметра';
                    ToolTip = 'Визначає стабільну бізнес-семантику параметра. Значення вибирається зі спільного довідника семантик атрибутів і параметрів продукту.';
                }

                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    Caption = 'Джерело посилання';
                    Visible = Rec."Value Type" = Rec."Value Type"::Reference;
                    ToolTip = 'Визначає кероване джерело, з якого вибирається значення посилального параметра.';
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає одиницю виміру для числового значення параметра.';
                }

                field("Value Prefix"; Rec."Value Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає текст, який додається перед значенням параметра.';
                }

                field("Value Suffix"; Rec."Value Suffix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає текст, який додається після значення параметра.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення параметрів.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання параметра.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ParameterValues)
            {
                ApplicationArea = All;
                Caption = 'Допустимі значення';
                Image = List;
                ToolTip = 'Відкриває перелік допустимих значень вибраного параметра.';
                Enabled = Rec."Value Type" =
                    Rec."Value Type"::"Controlled Value";

                trigger OnAction()
                var
                    ParameterValue: Record "SI Parameter Value";
                begin
                    Rec.TestField(Code);

                    ParameterValue.SetRange(
                        "Parameter Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Parameter Values",
                        ParameterValue);
                end;
            }
        }

        area(Promoted)
        {
            actionref(ParameterValuesPromoted; ParameterValues)
            {
            }
        }
    }
}