pageextension 65002 "SI IW IWSVehicle List Ext"
    extends IWSVehicleList
{
    layout
    {
        addafter("Registration No.")
        {
            field("SI Vehicle No."; Rec."SI Vehicle No.")
            {
                ApplicationArea = All;
                Caption = 'SI Vehicle No.';
                ToolTip = 'Ідентифікатор транспортного засобу в SI Vehicle Management.';
                Editable = false;
            }
        }

        modify("Registration No.")
        {
            Editable = false;
        }

        modify(Make)
        {
            Editable = false;
        }

        modify(Model)
        {
            Editable = false;
        }

        modify("Vehicle Category")
        {
            Editable = false;
        }
    }
}