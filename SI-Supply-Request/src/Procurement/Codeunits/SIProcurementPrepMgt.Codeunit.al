codeunit 61015 "SI Procurement Prep. Mgt."
{
    procedure SelectVendor(var MaterialReq: Record "SI Supply Material Req.")
    var
        Item: Record Item;
        VendorCategory: Record "SI Vendor Item Category";
        AllowedVendors: Page "SI Allowed Vendors";
    begin
        ValidateShortage(MaterialReq);
        Item.Get(MaterialReq."Item No.");
        Item.TestField("Item Category Code");

        AllowedVendors.LoadAllowedVendors(Item."Item Category Code");
        AllowedVendors.LookupMode(true);
        if AllowedVendors.RunModal() <> Action::LookupOK then
            exit;
        AllowedVendors.GetRecord(VendorCategory);

        MaterialReq."Selected Vendor No." := VendorCategory."Vendor No.";
        MaterialReq.Modify(true);
    end;

    procedure AddToProcurement(var MaterialReq: Record "SI Supply Material Req.")
    var
        Item: Record Item;
        VendorCategory: Record "SI Vendor Item Category";
        Batch: Record "SI Procurement Batch";
        ProcLine: Record "SI Procurement Line";
        ExistingLine: Record "SI Procurement Line";
        NextLineNo: Integer;
    begin
        ValidateShortage(MaterialReq);
        MaterialReq.TestField("Selected Vendor No.");
        Item.Get(MaterialReq."Item No.");
        Item.TestField("Item Category Code");

        if not IsVendorAllowed(MaterialReq."Selected Vendor No.", Item."Item Category Code") then
            Error(VendorNotAllowedErr, MaterialReq."Selected Vendor No.", Item."Item Category Code");

        ExistingLine.SetRange("Decision No.", MaterialReq."Decision No.");
        ExistingLine.SetRange("Decision Line No.", MaterialReq."Decision Line No.");
        ExistingLine.SetRange("Allocation Line No.", MaterialReq."Allocation Line No.");
        ExistingLine.SetRange("Requirement Line No.", MaterialReq."Line No.");
        if ExistingLine.FindFirst() then
            Error(AlreadyStagedErr, ExistingLine."Batch No.");

        GetOrCreateDraftBatch(Batch);
        ProcLine.SetRange("Batch No.", Batch."No.");
        if ProcLine.FindLast() then
            NextLineNo := ProcLine."Line No." + 10000
        else
            NextLineNo := 10000;

        ProcLine.Init();
        ProcLine."Batch No." := Batch."No.";
        ProcLine."Line No." := NextLineNo;
        ProcLine."Vendor No." := MaterialReq."Selected Vendor No.";
        ProcLine."Item No." := MaterialReq."Item No.";
        ProcLine."Variant Code" := MaterialReq."Variant Code";
        ProcLine.Description := MaterialReq.Description;
        ProcLine."Item Category Code" := Item."Item Category Code";
        ProcLine.Quantity := MaterialReq."Shortage Quantity";
        ProcLine."Unit of Measure Code" := MaterialReq."Unit of Measure Code";
        ProcLine."Location Code" := MaterialReq."Location Code";
        ProcLine."Decision No." := MaterialReq."Decision No.";
        ProcLine."Decision Line No." := MaterialReq."Decision Line No.";
        ProcLine."Allocation Line No." := MaterialReq."Allocation Line No.";
        ProcLine."Requirement Line No." := MaterialReq."Line No.";
        ProcLine."Added By User ID" := CopyStr(UserId(), 1, MaxStrLen(ProcLine."Added By User ID"));
        ProcLine."Added At" := CurrentDateTime();
        ProcLine.Insert(true);

        MaterialReq."Procurement Batch No." := Batch."No.";
        MaterialReq.Modify(true);

        Batch."Last Modified At" := CurrentDateTime();
        Batch.Modify(true);
    end;

    procedure OpenDraftPreview()
    var
        Batch: Record "SI Procurement Batch";
        ProcLine: Record "SI Procurement Line";
    begin
        if not FindDraftBatch(Batch) then
            Error(NoDraftBatchErr);
        ProcLine.SetRange("Batch No.", Batch."No.");
        Page.Run(Page::"SI Procurement Preview", ProcLine);
    end;

    procedure IsVendorAllowed(VendorNo: Code[20]; ItemCategoryCode: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        VendorCategory: Record "SI Vendor Item Category";
        CurrentCategoryCode: Code[20];
    begin
        CurrentCategoryCode := ItemCategoryCode;
        while CurrentCategoryCode <> '' do begin
            if VendorCategory.Get(VendorNo, CurrentCategoryCode) then
                if VendorCategory.Active then
                    exit(true);

            if not ItemCategory.Get(CurrentCategoryCode) then
                exit(false);
            CurrentCategoryCode := ItemCategory."Parent Category";
        end;
        exit(false);
    end;

    local procedure GetOrCreateDraftBatch(var Batch: Record "SI Procurement Batch")
    begin
        if FindDraftBatch(Batch) then
            exit;

        Batch.Init();
        Batch."No." := NewBatchNo();
        Batch.Status := Batch.Status::Draft;
        Batch."Created By User ID" := CopyStr(UserId(), 1, MaxStrLen(Batch."Created By User ID"));
        Batch."Created At" := CurrentDateTime();
        Batch."Last Modified At" := Batch."Created At";
        Batch.Insert(true);
    end;

    local procedure FindDraftBatch(var Batch: Record "SI Procurement Batch"): Boolean
    begin
        Batch.Reset();
        Batch.SetRange("Created By User ID", CopyStr(UserId(), 1, MaxStrLen(Batch."Created By User ID")));
        Batch.SetRange(Status, Batch.Status::Draft);
        exit(Batch.FindFirst());
    end;

    local procedure NewBatchNo(): Code[20]
    var
        GuidText: Text;
    begin
        GuidText := DelChr(Format(CreateGuid()), '=', '{}-');
        exit(CopyStr('PR-' + GuidText, 1, 20));
    end;

    local procedure ValidateShortage(MaterialReq: Record "SI Supply Material Req.")
    begin
        if MaterialReq."Shortage Quantity" <= 0 then
            Error(NoShortageErr);
    end;

    var
        NoShortageErr: Label 'Для цього матеріалу немає дефіциту, тому закупівля не потрібна.';
        NoAllowedVendorsErr: Label 'Для категорії %1 матеріалу %2 не налаштовано дозволених постачальників.';
        VendorNotAllowedErr: Label 'Постачальник %1 не дозволений для категорії %2.';
        AlreadyStagedErr: Label 'Цей дефіцит уже додано до підготовки закупівлі %1.';
        NoDraftBatchErr: Label 'Немає активної підготовки закупівлі для поточного користувача.';
}
