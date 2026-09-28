page 53011 "SI Param. Values Part"
{
    PageType = ListPart;
    SourceTable = "SI Parameter Value";
    ApplicationArea = All;
    Caption = 'Допустимі значення';
    DelayedInsert = true;
    PopulateAllFields = true;

    SourceTableView =
        sorting(
            "Parameter Code",
            "Sort Order",
            Code);

    layout
    {
        area(Content)
        {
            repeater(Values)
            {
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
                    ToolTip = 'Визначає значення, яке бачить користувач.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає розгорнуту назву значення.';
                }

                field("ERP Code"; Rec."ERP Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає компактний сегмент ERP-коду для Item або Item Variant.';
                }

                field("Numeric Value"; Rec."Numeric Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає числову семантику значення.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок відображення.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано значення.';
                }
            }
        }
    }
}