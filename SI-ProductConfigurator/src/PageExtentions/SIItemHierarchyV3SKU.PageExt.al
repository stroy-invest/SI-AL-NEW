pageextension 53092 "SI Item Hierarchy V3 SKU" extends "SI Item Hierarchy V3 Test"
{
    actions
    {
        addlast(Processing)
        {
            action(ConfigureStorageLocationsV3)
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
            actionref(ConfigureStorageLocationsV3Promoted; ConfigureStorageLocationsV3)
            {
            }
        }
    }
}
