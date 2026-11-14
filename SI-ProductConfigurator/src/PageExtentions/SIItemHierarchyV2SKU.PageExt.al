pageextension 53091 "SI Item Hierarchy V2 SKU" extends "SI Item Hierarchy V2"
{
    actions
    {
        addlast(Processing)
        {
            action(ConfigureStorageLocations)
            {
                ApplicationArea = All;
                Caption = 'Налаштувати місця зберігання';
                ToolTip = 'Створює стандартні SKU Business Central для вибраного товару або варіанта на вибраних складах.';
                Image = Warehouse;

                trigger OnAction()
                var
                    SKULocationMgt: Codeunit "SI SKU Location Mgt.";
                begin
                    SKULocationMgt.ConfigureFromCurrentContext();
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(ConfigureStorageLocationsPromoted; ConfigureStorageLocations)
            {
            }
        }
    }
}
