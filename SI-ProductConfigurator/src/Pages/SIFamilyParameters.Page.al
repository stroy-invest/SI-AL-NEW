page 53005 "SI Family Parameters"
{
    PageType = List;
    SourceTable = "SI Family Parameter";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Параметри сімейств';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає сімейство, для якого налаштовано параметр.';
                }

                field("Parameter Code"; Rec."Parameter Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає параметр, доступний для цього сімейства.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProductParameter: Record "SI Product Parameter";
                        AvailableParameters: Page "SI Wiz. Avail. Params";
                    begin
                        Rec.TestField("Family Code");

                        Clear(AvailableParameters);
                        AvailableParameters.LoadForFamily(Rec."Family Code");
                        AvailableParameters.LookupMode(true);

                        if AvailableParameters.RunModal() <> Action::LookupOK then
                            exit(false);

                        AvailableParameters.GetRecord(ProductParameter);

                        Rec.Validate(
                            "Parameter Code",
                            ProductParameter.Code);

                        Text := Rec."Parameter Code";

                        exit(true);
                    end;
                }

                field("Parameter Order"; Rec."Parameter Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає загальний порядок параметра в конфігураторі.';
                }

                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи обов’язково задавати значення параметра.';
                }

                field("ERP Projection Role"; Rec."ERP Projection Role")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи формує параметр Item, Item Variant або не бере участі в ERP-проєкції.';
                }

                field("Include in Description"; Rec."Include in Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи входить значення параметра до назви продукту.';
                }

                field("Description Order"; Rec."Description Order")
                {
                    ApplicationArea = All;
                    Editable = Rec."Include in Description";
                    ToolTip = 'Визначає порядок значення параметра у назві продукту.';
                }

                field("Include in Search"; Rec."Include in Search")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи використовується значення параметра в пошуковому представленні.';
                }

                field("Recipe Relevant"; Rec."Recipe Relevant")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи має параметр технологічне значення для вибору або формування рецептури.';
                }

                field("Default Value Code"; Rec."Default Value Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає контрольоване значення параметра, яке підставляється за замовчуванням.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання цього параметра в сімействі.';
                }
            }
        }
    }
}