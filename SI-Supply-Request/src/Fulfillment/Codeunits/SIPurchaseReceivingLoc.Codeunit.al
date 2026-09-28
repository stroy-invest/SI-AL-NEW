codeunit 61059 "SI Purchase Receiving Loc."
{
    procedure ResolveDefault(ItemNo: Code[20]; VariantCode: Code[10]): Code[10]
    var
        SKU: Record "Stockkeeping Unit";
        Location: Record Location;
        CandidateLocationCode: Code[10];
        CandidateCount: Integer;
    begin
        if ItemNo = '' then
            exit('');

        // Standard-first: SKU is the only source for an automatic Purchase Receiving Location.
        // If no SKU exists, or more than one allowed SKU makes the result ambiguous, leave it blank.
        SKU.SetRange("Item No.", ItemNo);
        SKU.SetRange("Variant Code", VariantCode);
        if SKU.FindSet() then
            repeat
                if (SKU."Location Code" <> '') and Location.Get(SKU."Location Code") then
                    if IsAllowedReceivingLocation(Location) then begin
                        CandidateCount += 1;
                        CandidateLocationCode := SKU."Location Code";
                        if CandidateCount > 1 then
                            exit('');
                    end;
            until SKU.Next() = 0;

        if CandidateCount = 1 then
            exit(CandidateLocationCode);

        exit('');
    end;

    procedure ValidateReceivingLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit;

        Location.Get(LocationCode);
        if not IsAllowedReceivingLocation(Location) then
            Error(ForbiddenLocationErr, Location.Name, Location.Code, Location."SI Location Type Code");
    end;

    procedure IsAllowedReceivingLocation(Location: Record Location): Boolean
    var
        LocationSetup: Record "SI Location Setup";
    begin
        // The business meaning of a Location Type is defined by Foundation Location Setup.
        // Never compare Location Type codes or captions to hard-coded values here.
        LocationSetup.Get('');

        exit(not IsForbiddenLocationType(Location."SI Location Type Code", LocationSetup));
    end;

    local procedure IsForbiddenLocationType(LocationTypeCode: Code[20]; LocationSetup: Record "SI Location Setup"): Boolean
    begin
        exit(
            ((LocationSetup."Finished Goods Type" <> '') and (LocationTypeCode = LocationSetup."Finished Goods Type")) or
            ((LocationSetup."Project Location Type" <> '') and (LocationTypeCode = LocationSetup."Project Location Type")) or
            ((LocationSetup."Vehicle Location Type" <> '') and (LocationTypeCode = LocationSetup."Vehicle Location Type")) or
            ((LocationSetup."Department Location Type" <> '') and (LocationTypeCode = LocationSetup."Department Location Type")));
    end;

    var
        ForbiddenLocationErr: Label 'Склад %1 (%2) не може використовуватися як Склад приходу для закупівлі. Семантичний тип %3 заборонений для закупівельного приходу.';
}
