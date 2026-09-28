page 58007 "SI Item Derived UoM Values"
{
    PageType = List;
    SourceTable = "SI Item Derived UoM Value";
    Caption = 'Похідні фізичні параметри товару';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Товар, для якого задано фізичний параметр.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Варіант товару. Порожнє значення означає параметр за замовчуванням для всіх варіантів товару.';
                }
                field("Derived UoM Code"; Rec."Derived UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Похідна одиниця, що задає фізичний зв’язок, наприклад KG/M3 для щільності.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Значення фізичного параметра у вибраній похідній одиниці.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Довільний опис параметра.';
                }
            }
        }
    }
}
