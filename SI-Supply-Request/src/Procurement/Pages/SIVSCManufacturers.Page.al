page 61035 "SI VSC Manufacturers"
{
    PageType = ListPart;
    SourceTable = "SI VSC Manufacturer";
    Caption = 'Виробники';
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Manufacturers)
            {
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає виробника, продукцію якого постачальник може постачати через цей канал. Якщо список порожній, канал не обмежує виробника.';
                }
                field("Manufacturer Name"; Rec."Manufacturer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує назву виробника.';
                }
            }
        }
    }
}
