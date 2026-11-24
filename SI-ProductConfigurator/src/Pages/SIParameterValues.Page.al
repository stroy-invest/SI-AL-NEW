page 53004 "SI Parameter Values"
{
    PageType = List;
    SourceTable = "SI Parameter Value";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Допустимі значення параметрів';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Values)
            {
                field("Parameter Code"; Rec."Parameter Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає параметр, якому належить значення.';
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільний код значення параметра.';
                }

                field("Display Value"; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає значення, яке відображається користувачеві та може використовуватися у назві продукту.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає розгорнуту назву значення параметра.';
                }

                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає англійську назву значення параметра.';
                }

                field("ERP Code"; Rec."ERP Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає компактний сегмент ERP-коду для Item або Item Variant.';
                }

                field("Numeric Value"; Rec."Numeric Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає нормативне числове значення, пов’язане зі значенням параметра';
                }
				// Додано 11.08.2026
                field("Numeric UoM"; Rec."Numeric UoM Code")
                {
                    Caption = 'Одиниця виміру';
					ApplicationArea = All;
                    ToolTip = 'Визначає одиницю виміру числового значення';
                }
				
                field("Numeric Meaning"; Rec."Numeric Meaning")
                {
                    Caption = 'Зміст числового значення';
					ApplicationArea = All;
					Editable = false;
                    ToolTip = 'Визначає зміст числового значення';
                }					
				//-------------------------
                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення значень.';
                }

                field("Ever Used"; Rec."Ever Used")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Значення вже використовувалося в матеріалізованій ERP-проєкції.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання значення.';
                }
            }
        }
        area(FactBoxes)
        {
            part(ValueAttrFactBox; "SI Value Attr. FactBox")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AttributeDefinitions)
            {
                ApplicationArea = All;
                Caption = 'Визначення характеристик';
                trigger OnAction()
                var
                    AttrDef: Record "SI Value Attr. Definition";
                begin
                    CurrPage.SaveRecord();
                AttrDef.SetRange("Parameter Code", Rec."Parameter Code");
                Page.RunModal(Page::"SI Value Attr. Definitions", AttrDef);
                    CurrPage.ValueAttrFactBox.Page.LoadAttributes(Rec."Parameter Code", Rec.Code);
                end;
            }
            action(ValueAttributes)
            {
                ApplicationArea = All;
                Caption = 'Додаткові характеристики';
                trigger OnAction()
                var
                    Attr: Record "SI Parameter Value Attr.";
                begin
                    CurrPage.SaveRecord();
                Attr.SetRange("Parameter Code", Rec."Parameter Code");
                Attr.SetRange("Value Code", Rec.Code);
                Page.RunModal(Page::"SI Parameter Value Attrs", Attr);
                    CurrPage.ValueAttrFactBox.Page.LoadAttributes(Rec."Parameter Code", Rec.Code);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.ValueAttrFactBox.Page.LoadAttributes(Rec."Parameter Code", Rec.Code);
    end;

}
