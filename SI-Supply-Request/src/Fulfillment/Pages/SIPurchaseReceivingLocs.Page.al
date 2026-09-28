page 61058 "SI Purchase Receiving Locs"
{
    Caption = 'Склади приходу';
    PageType = List;
    SourceTable = Location;
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Locations)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("SI Location Type Code"; Rec."SI Location Type Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Location: Record Location;
        ReceivingLocationMgt: Codeunit "SI Purchase Receiving Loc.";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if Location.FindSet() then
            repeat
                if ReceivingLocationMgt.IsAllowedReceivingLocation(Location) then begin
                    Rec := Location;
                    Rec.Insert();
                end;
            until Location.Next() = 0;

        Rec.Reset();
    end;
}
