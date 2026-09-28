page 61049 "SI Proc. Plan Demand Links"
{
    PageType = List;
    SourceTable = "SI Proc. Plan Demand Link";
    Caption = 'Походження потреби';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ProductName; ProductName)
                {
                    ApplicationArea = All;
                    Caption = 'Товар / матеріал';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenProduct();
                    end;
                }
                field(DemandQuantity; DemandQuantity) { ApplicationArea = All; Caption = 'Початкова потреба'; DecimalPlaces = 0 : 5; }
                field(UoMCode; UoMCode) { ApplicationArea = All; Caption = 'Од. вим.'; }
                field(ProjectName; ProjectName)
                {
                    ApplicationArea = All;
                    Caption = 'Проєкт';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenProject();
                    end;
                }
                field(SiteName; SiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Буд. майданчик';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenSite();
                    end;
                }
                field(RequestDescription; RequestDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Заявка / потреба';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenRequest();
                    end;
                }
                field(RequiredOnSiteAt; RequiredOnSiteAt) { ApplicationArea = All; Caption = 'Потрібно на майданчику'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Demand: Record "SI Planning Demand";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Project: Record Job;
        Site: Record "SI Construction Site";
        Request: Record "SI Supply Req Header";
    begin
        Clear(ProductName);
        Clear(DemandQuantity);
        Clear(UoMCode);
        Clear(ProjectName);
        Clear(SiteName);
        Clear(RequestDescription);
        Clear(RequiredOnSiteAt);
        Clear(CurrentItemNo);
        Clear(CurrentVariantCode);
        Clear(CurrentProjectNo);
        Clear(CurrentSiteCode);
        Clear(CurrentRequestNo);

        if not Demand.Get(Rec."Planning Demand Entry No.") then
            exit;

        CurrentItemNo := Demand."Item No.";
        CurrentVariantCode := Demand."Variant Code";
        CurrentProjectNo := Demand."Project No.";
        CurrentSiteCode := Demand."Construction Site Code";
        CurrentRequestNo := Demand."Request No.";

        if (CurrentVariantCode <> '') and ItemVariant.Get(CurrentItemNo, CurrentVariantCode) then
            ProductName := ItemVariant.Description
        else
            if Item.Get(CurrentItemNo) then
                ProductName := Item.Description;
        if ProductName = '' then
            ProductName := Demand.Description;

        DemandQuantity := Demand.Quantity;
        UoMCode := Demand."Unit of Measure Code";
        RequiredOnSiteAt := Demand."Required on Site At";

        if Project.Get(CurrentProjectNo) then
            ProjectName := Project.Description;

        if Site.Get(CurrentProjectNo, CurrentSiteCode) then
            SiteName := Site.Name;

        if Request.Get(CurrentRequestNo) then begin
            RequestDescription := Request.Description;
            if RequestDescription = '' then
                RequestDescription := 'Заявка на забезпечення';
        end;
    end;

    local procedure OpenProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if CurrentVariantCode <> '' then begin
            if not ItemVariant.Get(CurrentItemNo, CurrentVariantCode) then
                exit;
            ItemVariant.SetRecFilter();
            Page.Run(Page::"Item Variants", ItemVariant);
            exit;
        end;
        if Item.Get(CurrentItemNo) then
            Page.Run(Page::"Item Card", Item);
    end;

    local procedure OpenProject()
    var
        Project: Record Job;
    begin
        if Project.Get(CurrentProjectNo) then
            Page.Run(Page::"Job Card", Project);
    end;

    local procedure OpenSite()
    var
        Site: Record "SI Construction Site";
    begin
        if Site.Get(CurrentProjectNo, CurrentSiteCode) then
            Page.Run(Page::"SI Construction Site Card", Site);
    end;

    local procedure OpenRequest()
    var
        Request: Record "SI Supply Req Header";
    begin
        if Request.Get(CurrentRequestNo) then
            Page.Run(Page::"SI Supply Req Card", Request);
    end;

    var
        ProductName: Text[100];
        DemandQuantity: Decimal;
        UoMCode: Code[10];
        ProjectName: Text[100];
        SiteName: Text[100];
        RequestDescription: Text[250];
        RequiredOnSiteAt: DateTime;
        CurrentItemNo: Code[20];
        CurrentVariantCode: Code[10];
        CurrentProjectNo: Code[20];
        CurrentSiteCode: Code[20];
        CurrentRequestNo: Code[20];
}
