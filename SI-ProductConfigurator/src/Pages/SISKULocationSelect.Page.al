page 53038 "SI SKU Location Select"
{
    PageType = NavigatePage;
    SourceTable = "SI SKU Location Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Налаштувати місця зберігання';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Товар';

                field(ItemDisplay; ItemDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Editable = false;
                }
                field(VariantDisplay; VariantDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Editable = false;
                    Visible = VariantVisible;
                }
            }

            repeater(Locations)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрати';
                    Editable = not Rec."SKU Exists";
                    ToolTip = 'Позначте склад, для якого потрібно створити стандартну одиницю обліку запасів (SKU).';
                }
                field("Location Name"; Rec."Location Name")
                {
                    ApplicationArea = All;
                    Caption = 'Склад';
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Editable = false;
                }
                field("Location Type Name"; Rec."Location Type Name")
                {
                    ApplicationArea = All;
                    Caption = 'Тип складу';
                    Editable = false;
                }
                field("SKU Exists"; Rec."SKU Exists")
                {
                    ApplicationArea = All;
                    Caption = 'SKU вже існує';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                ApplicationArea = All;
                Caption = 'Застосувати';
                ToolTip = 'Створює SKU для вибраних місць зберігання.';
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ApplyRequested := true;
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                ToolTip = 'Закриває сторінку без створення SKU.';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ApplyRequested := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    procedure WasApplyRequested(): Boolean
    begin
        exit(ApplyRequested);
    end;

    procedure Load(ItemNo: Code[20]; VariantCode: Code[10])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        LocationType: Record "SI Location Type";
        LocationSetup: Record "SI Location Setup";
        SKU: Record "Stockkeeping Unit";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        Item.Get(ItemNo);
        ItemDisplay := Item.Description;
        if ItemDisplay = '' then
            ItemDisplay := Item."No.";

        VariantVisible := VariantCode <> '';
        Clear(VariantDisplay);
        if VariantVisible then begin
            ItemVariant.Get(ItemNo, VariantCode);
            VariantDisplay := ItemVariant.Description;
            if VariantDisplay = '' then
                VariantDisplay := ItemVariant.Code;
        end;

        if not LocationSetup.Get() then
            Error(LocationSetupMissingErr);

        Location.SetRange("Use As In-Transit", false);
        if Location.FindSet() then
            repeat
                if IsAllowedLocationType(Location."SI Location Type Code", LocationSetup) then begin
                    Rec.Init();
                    Rec."Location Code" := Location.Code;
                    Rec."Location Name" := Location.Name;
                    Rec."Location Type Code" := Location."SI Location Type Code";
                    if LocationType.Get(Location."SI Location Type Code") then
                        Rec."Location Type Name" := LocationType.Description;
                    Rec."SKU Exists" := SKU.Get(Location.Code, ItemNo, VariantCode);
                    Rec.Selected := false;
                    Rec.Insert();
                end;
            until Location.Next() = 0;

        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    procedure GetSelected(var TempSelection: Record "SI SKU Location Buffer" temporary)
    begin
        TempSelection.Reset();
        TempSelection.DeleteAll();

        Rec.Reset();
        Rec.SetRange(Selected, true);
        Rec.SetRange("SKU Exists", false);
        if Rec.FindSet() then
            repeat
                TempSelection := Rec;
                TempSelection.Insert();
            until Rec.Next() = 0;
    end;

    local procedure IsAllowedLocationType(LocationTypeCode: Code[20]; LocationSetup: Record "SI Location Setup"): Boolean
    begin
        if LocationTypeCode = '' then
            exit(false);

        exit(
            (LocationTypeCode = LocationSetup."Main Warehouse Type") or
            (LocationTypeCode = LocationSetup."Material Warehouse Type") or
            (LocationTypeCode = LocationSetup."Metal Warehouse Type") or
            (LocationTypeCode = LocationSetup."Fuel Warehouse Type"));
    end;

    var
        ItemDisplay: Text[200];
        VariantDisplay: Text[200];
        VariantVisible: Boolean;
        ApplyRequested: Boolean;
        LocationSetupMissingErr: Label 'Не налаштовано типи складів у SI Location Setup.';
}
