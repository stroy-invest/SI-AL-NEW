page 53003 "SI Product Param. Card"
{
    PageType = Card;
    SourceTable = "SI Product Parameter";
    ApplicationArea = All;
    Caption = 'Параметр продукту';

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
                    Importance = Promoted;
                    ToolTip = 'Визначає тип значень, які може приймати параметр.';

                    trigger OnValidate()
                    begin
                        UpdateSourceVisibility();
                        CurrPage.Update(false);
                    end;
                }

                field("SI Semantic Code"; Rec."SI Semantic Code")
                {
                    ApplicationArea = All;
                    Caption = 'Семантика параметра';
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільну бізнес-семантику параметра. Значення вибирається зі спільного довідника семантик атрибутів і параметрів продукту.';
                }

                field("Value Source"; Rec."Value Source")
                {
                    ApplicationArea = All;
                    Visible = ShowValueSource;

                    trigger OnValidate()
                    begin
                        UpdateSourceVisibility();
                        CurrPage.Update(false);
                    end;
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    Caption = 'Джерело посилання';
                    Visible = ShowReferenceSource;
                    ToolTip = 'Визначає кероване джерело, з якого вибирається значення посилального параметра.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання параметра.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення параметра.';
                }
            }

            group(SourceSettings)
            {
                Caption = 'Налаштування джерела значень';
                Visible = ShowNominalSource;

                field("Mapping Set Code"; Rec."Mapping Set Code")
                {
                    ApplicationArea = All;
                }
                field("Nominal Value Field"; Rec."Nominal Value Field")
                {
                    ApplicationArea = All;
                }
            }

            group(ValueFormat)
            {
                Caption = 'Формат значення';

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
                ToolTip = 'Відкриває перелік допустимих значень цього параметра.';
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSourceVisibility();
    end;

    var
        ShowValueSource: Boolean;
        ShowNominalSource: Boolean;
        ShowReferenceSource: Boolean;

    local procedure UpdateSourceVisibility()
    begin
        ShowValueSource := Rec."Value Type" = Rec."Value Type"::"Controlled Value";
        ShowNominalSource := ShowValueSource and (Rec."Value Source" = Rec."Value Source"::NominalSize);
        ShowReferenceSource := Rec."Value Type" = Rec."Value Type"::Reference;
    end;
}
