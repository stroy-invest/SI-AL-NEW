page 61050 "SI Proc. Planning Board"
{
    PageType = List;
    SourceTable = "SI Proc. Plan Snapshot";
    Caption = 'Планування закупівель';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(PlanInfo)
            {
                Caption = 'Актуальний план';
                field(PlanCreatedAt; PlanCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Оновлено';
                    Editable = false;
                }
                field(PlanningPeriod; PlanningPeriod)
                {
                    ApplicationArea = All;
                    Caption = 'Горизонт планування';
                    Editable = false;
                }
            }
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
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Треба закупити';
                }
                field(AllocatedQuantity; AllocatedQuantity)
                {
                    ApplicationArea = All;
                    Caption = 'Розподілено';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenAllocationsForCurrentLine();
                    end;
                }
                field(RemainingQuantity; RemainingQuantity)
                {
                    ApplicationArea = All;
                    Caption = 'Нерозподілено';
                    DecimalPlaces = 0 : 5;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Од. вим.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Забезпечити до';
                }
                field(LocationName; LocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenLocation();
                    end;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                    Caption = 'Замовити не пізніше';
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = All;
                    Caption = 'Рекомендація BC';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshPlan)
            {
                Caption = 'Оновити план закупівель';
                ApplicationArea = All;
                Image = CalculatePlan;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    PlanningRunner: Codeunit "SI Proc. Planning Runner";
                begin
                    PlanningRunner.RefreshPlan();
                    LoadCurrentRun();
                    CurrPage.Update(false);
                end;
            }
            action(SelectSupply)
            {
                Caption = 'Вибрати постачання';
                ApplicationArea = All;
                Image = Vendor;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    SelectSupplyForCurrentLine();
                    LoadAllocationValues();
                    CurrPage.Update(false);
                end;
            }
            action(OpenAllocations)
            {
                Caption = 'Розподіл постачання';
                ApplicationArea = All;
                Image = Allocations;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    OpenAllocationsForCurrentLine();
                end;
            }
            action(OpenSupplyPlan)
            {
                Caption = 'План постачання';
                ApplicationArea = All;
                Image = Planning;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    OpenCurrentSupplyPlan();
                end;
            }
            action(OpenPOPreparation)
            {
                Caption = 'Підготовка замовлень';
                ApplicationArea = All;
                Image = Purchase;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ProposalMgt: Codeunit "SI PO Proposal Mgt.";
                begin
                    ProposalMgt.RebuildCurrentRun();
                    Page.Run(Page::"SI PO Preparation");
                end;
            }
            action(OpenDemandLinks)
            {
                Caption = 'Походження потреби';
                ApplicationArea = All;
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    Link: Record "SI Proc. Plan Demand Link";
                begin
                    Link.SetRange("Run No.", Rec."Run No.");
                    Link.SetRange("Snapshot Line No.", Rec."Line No.");
                    Page.Run(Page::"SI Proc. Plan Demand Links", Link);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadCurrentRun();
    end;

    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues();
        LoadAllocationValues();
    end;

    local procedure LoadCurrentRun()
    var
        Run: Record "SI Proc. Plan Run";
    begin
        Run.SetRange(Current, true);
        if not Run.FindLast() then
            Error(NoPlanErr);

        Rec.SetRange("Run No.", Run."Run No.");
        PlanCreatedAt := Run."Created At";
        PlanningPeriod := StrSubstNo('%1 — %2', Run."Planning Start Date", Run."Planning End Date");
    end;

    local procedure LoadDisplayValues()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
    begin
        Clear(ProductName);
        Clear(LocationName);

        if (Rec."Variant Code" <> '') and ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
            ProductName := ItemVariant.Description
        else
            if Item.Get(Rec."Item No.") then
                ProductName := Item.Description;
        if ProductName = '' then
            ProductName := Rec.Description;

        if Location.Get(Rec."Location Code") then
            LocationName := Location.Name;
    end;

    local procedure OpenProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if Rec."Variant Code" <> '' then begin
            if not ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
                exit;
            ItemVariant.SetRecFilter();
            Page.Run(Page::"Item Variants", ItemVariant);
            exit;
        end;

        if Item.Get(Rec."Item No.") then
            Page.Run(Page::"Item Card", Item);
    end;

    local procedure OpenLocation()
    var
        Location: Record Location;
    begin
        if Location.Get(Rec."Location Code") then
            Page.Run(Page::"Location Card", Location);
    end;

    local procedure LoadAllocationValues()
    var
        AllocationMgt: Codeunit "SI Proc. Allocation Mgt.";
    begin
        AllocatedQuantity := AllocationMgt.GetAllocatedQuantity(Rec."Run No.", Rec."Line No.");
        RemainingQuantity := Rec.Quantity - AllocatedQuantity;
        if RemainingQuantity < 0 then
            RemainingQuantity := 0;
    end;

    local procedure SelectSupplyForCurrentLine()
    var
        Resolver: Codeunit "SI VSC Resolver";
        AllocationMgt: Codeunit "SI Proc. Allocation Mgt.";
        Candidate: Record "SI VSC Candidate" temporary;
        SelectedCandidate: Record "SI VSC Candidate" temporary;
        CandidatePage: Page "SI VSC Resolver Results";
        QtyToSource: Decimal;
    begin
        QtyToSource := Rec.Quantity - AllocationMgt.GetAllocatedQuantity(Rec."Run No.", Rec."Line No.");
        if QtyToSource <= 0 then
            Error(FullyAllocatedErr);

        // Manufacturer is intentionally blank in 4.5A: no manufacturer constraint is carried by the planning snapshot yet.
        Resolver.Resolve(Rec."Item No.", Rec."Variant Code", QtyToSource, Rec."Unit of Measure Code", Rec."Due Date", '', Candidate);
        if Candidate.IsEmpty() then
            Error(NoCandidatesErr, ProductName);

        CandidatePage.LoadCandidates(Candidate);
        CandidatePage.LookupMode(true);
        if CandidatePage.RunModal() <> Action::LookupOK then
            exit;
        if not CandidatePage.GetSelectedCandidate(SelectedCandidate) then
            exit;

        AllocationMgt.CreateFromCandidate(Rec, SelectedCandidate, SelectedCandidate."Suggested Purchase Quantity");
    end;

    local procedure OpenAllocationsForCurrentLine()
    var
        Allocation: Record "SI Procurement Allocation";
    begin
        Allocation.SetRange("Planning Run No.", Rec."Run No.");
        Allocation.SetRange("Snapshot Line No.", Rec."Line No.");
        Page.Run(Page::"SI Procurement Allocations", Allocation);
    end;

    local procedure OpenCurrentSupplyPlan()
    var
        Run: Record "SI Proc. Plan Run";
        Allocation: Record "SI Procurement Allocation";
    begin
        Run.SetRange(Current, true);
        if not Run.FindLast() then
            Error(NoPlanErr);

        Allocation.SetRange("Planning Run No.", Run."Run No.");
        Allocation.SetFilter(Status, '<>%1', Allocation.Status::Cancelled);
        Page.Run(Page::"SI Procurement Supply Plan", Allocation);
    end;

    var
        ProductName: Text[100];
        LocationName: Text[100];
        PlanCreatedAt: DateTime;
        PlanningPeriod: Text[100];
        AllocatedQuantity: Decimal;
        RemainingQuantity: Decimal;
        FullyAllocatedErr: Label 'Потреба вже повністю розподілена.';
        NoCandidatesErr: Label 'Для «%1» не знайдено доступних умов постачання.';
        NoPlanErr: Label 'Ще немає актуального плану закупівель. Виконайте «Оновити план закупівель».';
}
