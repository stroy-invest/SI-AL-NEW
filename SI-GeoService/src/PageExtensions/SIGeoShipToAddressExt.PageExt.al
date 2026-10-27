pageextension 63001 "SI Geo Ship-to Address Ext" extends "Ship-to Address"
{
    actions
    {
        addlast(Processing)
        {
            action(SIGeoShipToPoints)
            {
                ApplicationArea = All;
                Caption = 'Географічні точки';
                Image = Map;
                ToolTip = 'Відкрити операційні географічні точки цієї адреси доставки.';
                trigger OnAction()
                var
                    GeoPoint: Record "SI Geo Ship-to Point";
                begin
                    Rec.TestField("Customer No.");
                    Rec.TestField(Code);
                    GeoPoint.SetRange("Customer No.", Rec."Customer No.");
                    GeoPoint.SetRange("Ship-to Code", Rec.Code);
                    Page.Run(Page::"SI Geo Ship-to Points", GeoPoint);
                end;
            }
        }
    }
}
