pageextension 63000 "SI Geo Location Card Ext" extends "Location Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIGeoLocationPoints)
            {
                ApplicationArea = All;
                Caption = 'Географічні точки';
                ToolTip = 'Відкрити точки завантаження, розвантаження, в''їзду та виїзду для поточного складу.';
                Image = Map;

                trigger OnAction()
                var
                    GeoPoint: Record "SI Geo Location Point";
                begin
                    Rec.TestField(Code);

                    GeoPoint.SetRange("Location Code", Rec.Code);

                    Page.Run(
                        Page::"SI Geo Location Points",
                        GeoPoint);
                end;
            }
        }
    }
}