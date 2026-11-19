page 57220 "SI Prok Fact Hierarchy"
{
    PageType = List;
    SourceTable = "SI Prok Fact Tree Buffer";
    SourceTableTemporary = true;
    Caption = 'Факти виробництва Proktek (за заявками)';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Facts)
            {
                ShowAsTree = true;
                TreeInitialState = CollapseAll;
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Display Name";

                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'Заявка / факт / партія';
                    DrillDown = true;
                    ToolTip = 'Відкрити заявку BC або картку конкретного виробничого факту.';
                    trigger OnDrillDown()
                    begin
                        OpenCurrentRecord();
                    end;
                }
                field("Source No."; Rec."Source No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field("Proktek Order No."; Rec."Proktek Order No.") { ApplicationArea = All; }
                field(PlanDisplay; Rec."Plan Display") { ApplicationArea = All; Caption = 'План, м³'; }
                field(ActualDisplay; Rec."Actual Display") { ApplicationArea = All; Caption = 'Факт MES, м³'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportPlanFact)
            {
                ApplicationArea = All;
                Caption = 'Звіт план/факт';
                Image = ExportToExcel;
                Enabled = CanExport;
                ToolTip = 'Звіт за заявкою, за групою «Без замовлення» або за одним конкретним фактом. Факти відображаються незалежно від історичного способу приймання.';
                trigger OnAction()
                var
                    Exporter: Codeunit "SI Prok Plan Fact Excel";
                begin
                    case Rec."Node Type" of
                        Rec."Node Type"::Unlinked:
                            Exporter.ExportWithoutOrder();
                        Rec."Node Type"::Fact:
                            Exporter.ExportForFact(Rec."Fact Entry No.");
                        Rec."Node Type"::Request:
                            case Rec."Request Scope" of
                                Rec."Request Scope"::SupplyRequest:
                                    Exporter.ExportForSupplyRequest(Rec."Source No.");
                                Rec."Request Scope"::ProductionRequest:
                                    Exporter.ExportForProductionRequest(Rec."Prod. Request Entry No.");
                                else
                                    Error('Цей вузол не пов’язаний із заявкою.');
                            end;
                        else
                            Error('Для звіту виберіть заявку, групу «Без замовлення» або конкретний факт.');
                    end;
                end;
            }
            action(RefreshHierarchy)
            {
                ApplicationArea = All;
                Caption = 'Оновити ієрархію';
                Image = Refresh;
                trigger OnAction()
                begin
                    BuildTree();
                    CurrPage.Update(false);
                end;
            }
            action(OpenTechnicalList)
            {
                ApplicationArea = All;
                Caption = 'Технічний список фактів';
                Image = List;
                RunObject = page "SI Prok Production Facts";
            }
        }
        area(Promoted)
        {
            actionref(ExportPlanFactPromoted; ExportPlanFact) { }
            actionref(RefreshHierarchyPromoted; RefreshHierarchy) { }
        }
    }

    trigger OnOpenPage()
    begin
        BuildTree();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CanExport := ((Rec."Node Type" = Rec."Node Type"::Request) and
            (Rec."Request Scope" <> Rec."Request Scope"::None) and Rec."Has Facts") or
            ((Rec."Node Type" = Rec."Node Type"::Unlinked) and Rec."Has Facts") or
            ((Rec."Node Type" = Rec."Node Type"::Fact) and
             (Rec."Link State" <> Enum::"SI Prok PF Link State"::Broken));
    end;

    local procedure BuildTree()
    var
        Request: Record "SI Concrete Prod Request";
        GroupRequest: Record "SI Concrete Prod Request";
        Seen: Dictionary of [Text, Boolean];
        GroupKey: Text;
        RootEntryNo: Integer;
        FactNo: Integer;
        ActualQty: Decimal;
        ActualKnown: Boolean;
        IncludedCount: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        NextEntryNo := 0;

        // Every BC production request is shown, even when it has no facts.
        // A source Supply Request can own several production requests.
        if Request.FindSet() then
            repeat
                GroupKey := BuildGroupKey(Request);
                if not Seen.ContainsKey(GroupKey) then begin
                    Seen.Add(GroupKey, true);
                    InsertRoot(Request, RootEntryNo);
                    FactNo := 0;
                    ActualQty := 0;
                    ActualKnown := true;
                    IncludedCount := 0;
                    if IsSupplyGroup(Request) then begin
                        GroupRequest.SetRange("Source Type", GroupRequest."Source Type"::"Supply Request");
                        GroupRequest.SetRange("Source No.", Request."Source No.");
                        if GroupRequest.FindSet() then
                            repeat
                                InsertRequestFacts(GroupRequest, FactNo, ActualQty, ActualKnown, IncludedCount);
                            until GroupRequest.Next() = 0;
                        GroupRequest.Reset();
                    end else
                        InsertRequestFacts(Request, FactNo, ActualQty, ActualKnown, IncludedCount);
                    FinishRoot(RootEntryNo, FactNo, ActualQty, ActualKnown, IncludedCount, false);
                end;
            until Request.Next() = 0;

        // Separate genuine no-order facts from Proktek orders not linked to BC.
        InsertOtherFacts(Enum::"SI Prok PF Link State"::WithoutOrder);
        InsertOtherFacts(Enum::"SI Prok PF Link State"::Unmatched);
        InsertOtherFacts(Enum::"SI Prok PF Link State"::Broken);
        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    local procedure IsSupplyGroup(Request: Record "SI Concrete Prod Request"): Boolean
    begin
        exit((Request."Source Type" = Request."Source Type"::"Supply Request") and
            (Request."Source No." <> ''));
    end;

    local procedure BuildGroupKey(Request: Record "SI Concrete Prod Request"): Text
    begin
        if IsSupplyGroup(Request) then
            exit('S|' + Request."Source No.");
        exit('P|' + Format(Request."Entry No."));
    end;

    local procedure InsertRequestFacts(Request: Record "SI Concrete Prod Request"; var FactNo: Integer; var ActualQty: Decimal; var ActualKnown: Boolean; var IncludedCount: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Resolver: Codeunit "SI Prok PF Link Resolver";
        Qty: Decimal;
    begin
        Fact.SetCurrentKey("Entry No.");
        if Fact.FindSet() then
            repeat
                if Resolver.MatchesRequest(Fact, Request."Entry No.") then begin
                    FactNo += 1;
                    InsertFactWithParty(Fact, FactNo, Enum::"SI Prok PF Link State"::Linked);
                    IncludedCount += 1;
                    if TryReadProducedQuantity(Fact, Qty) then
                        ActualQty += Qty
                    else
                        ActualKnown := false;
                end;
            until Fact.Next() = 0;
    end;

    local procedure InsertOtherFacts(State: Enum "SI Prok PF Link State")
    var
        Fact: Record "SI Prok Production Fact";
        Request: Record "SI Concrete Prod Request";
        Resolver: Codeunit "SI Prok PF Link Resolver";
        RootEntryNo: Integer;
        FactNo: Integer;
        ActualQty: Decimal;
        ActualKnown: Boolean;
        IncludedCount: Integer;
        HasRoot: Boolean;
        Qty: Decimal;
    begin
        ActualKnown := true;
        Fact.SetCurrentKey("Entry No.");
        if Fact.FindSet() then
            repeat
                if Resolver.Resolve(Fact, Request) = State then begin
                    if not HasRoot then begin
                        InsertOtherRoot(State, RootEntryNo);
                        HasRoot := true;
                    end;
                    FactNo += 1;
                    InsertFactWithParty(Fact, FactNo, State);
                    IncludedCount += 1;
                    if TryReadProducedQuantity(Fact, Qty) then
                        ActualQty += Qty
                    else
                        ActualKnown := false;
                end;
            until Fact.Next() = 0;
        if HasRoot then
            FinishRoot(RootEntryNo, FactNo, ActualQty, ActualKnown, IncludedCount, State = Enum::"SI Prok PF Link State"::WithoutOrder);
    end;

    local procedure FinishRoot(RootEntryNo: Integer; FactCount: Integer; ActualQty: Decimal; ActualKnown: Boolean; IncludedCount: Integer; ConditionalPlan: Boolean)
    begin
        Rec.Get(RootEntryNo);
        Rec."Has Facts" := IncludedCount > 0;
        if ConditionalPlan then
            Rec."Plan Display" := '—'; // No BC order; no invented order plan.
        if FactCount = 0 then
            Rec."Actual Display" := 'Фактів немає'
        else
            if ActualKnown then begin
                Rec."Actual Quantity M3" := ActualQty;
                Rec."Quantity Known" := true;
                Rec."Actual Display" := Format(ActualQty);
            end else
                Rec."Actual Display" := 'Невідомо';
        Rec.Modify();
    end;

    local procedure InsertRoot(Request: Record "SI Concrete Prod Request"; var RootEntryNo: Integer)
    var
        GroupRequest: Record "SI Concrete Prod Request";
        Plan: Record "SI Prok Production Plan";
        CountRequests: Integer;
        PlanKnown: Boolean;
    begin
        Rec.Init();
        NextEntryNo += 1;
        RootEntryNo := NextEntryNo;
        Rec."Entry No." := RootEntryNo;
        Rec."Node Type" := Rec."Node Type"::Request;
        Rec.Indentation := 0;
        Rec."Source No." := Request."Source No.";
        Rec."Prod. Request Entry No." := Request."Entry No.";
        Rec."Item No." := Request."Item No.";
        PlanKnown := true;
        if IsSupplyGroup(Request) then begin
            Rec."Request Scope" := Rec."Request Scope"::SupplyRequest;
            GroupRequest.SetRange("Source Type", GroupRequest."Source Type"::"Supply Request");
            GroupRequest.SetRange("Source No.", Request."Source No.");
            if GroupRequest.FindSet() then
                repeat
                    CountRequests += 1;
                    if Plan.Get(GroupRequest."Entry No.") and (Plan."Unit of Measure Code" = 'M3') then
                        Rec."Planned Quantity M3" += Plan."Planned Quantity"
                    else
                        PlanKnown := false;
                until GroupRequest.Next() = 0;
            if CountRequests > 1 then
                Rec."Display Name" := CopyStr(StrSubstNo('Заявка %1 · %2 виробничі позиції', Request."Source No.", CountRequests), 1, 250)
            else
                Rec."Display Name" := CopyStr(StrSubstNo('Заявка %1 · %2', Request."Source No.", Request.GetProductDescription()), 1, 250);
        end else begin
            Rec."Request Scope" := Rec."Request Scope"::ProductionRequest;
            Rec."Display Name" := CopyStr(StrSubstNo('Виробнича заявка #%1 · %2', Request."Entry No.", Request.GetProductDescription()), 1, 250);
            if Plan.Get(Request."Entry No.") and (Plan."Unit of Measure Code" = 'M3') then
                Rec."Planned Quantity M3" := Plan."Planned Quantity"
            else
                PlanKnown := false;
        end;
        if PlanKnown then
            Rec."Plan Display" := Format(Rec."Planned Quantity M3")
        else
            Rec."Plan Display" := 'Немає плану в M3';
        Rec.Insert();
    end;

    local procedure InsertOtherRoot(State: Enum "SI Prok PF Link State"; var RootEntryNo: Integer)
    begin
        Rec.Init();
        NextEntryNo += 1;
        RootEntryNo := NextEntryNo;
        Rec."Entry No." := RootEntryNo;
        Rec.Indentation := 0;
        Rec."Link State" := State;
        case State of
            State::WithoutOrder:
                begin
                    Rec."Node Type" := Rec."Node Type"::Unlinked;
                    Rec."Display Name" := 'Без замовлення';
                end;
            State::Unmatched:
                begin
                    Rec."Node Type" := Rec."Node Type"::Unmatched;
                    Rec."Display Name" := 'Замовлення Proktek без зв’язку із заявкою BC';
                    Rec."Plan Display" := '—';
                end;
            State::Broken:
                begin
                    Rec."Node Type" := Rec."Node Type"::BrokenLink;
                    Rec."Display Name" := 'Помилки прив’язки до заявки';
                    Rec."Plan Display" := '—';
                end;
        end;
        Rec.Insert();
    end;

    local procedure InsertFactWithParty(Fact: Record "SI Prok Production Fact"; FactNo: Integer; State: Enum "SI Prok PF Link State")
    var
        FactNodeNo: Integer;
        Qty: Decimal;
    begin
        Rec.Init();
        NextEntryNo += 1;
        FactNodeNo := NextEntryNo;
        Rec."Entry No." := FactNodeNo;
        Rec."Node Type" := Rec."Node Type"::Fact;
        Rec."Link State" := State;
        Rec.Indentation := 1;
        Rec."Fact Entry No." := Fact."Entry No.";
        Rec."Prod. Request Entry No." := Fact."Prod. Request Entry No.";
        Rec."Production Date/Time" := Fact."Production Date/Time";
        Rec."Truck Plate" := CopyStr(Fact."Truck Plate", 1, MaxStrLen(Rec."Truck Plate"));
        Rec."Item No." := Fact."Item No.";
        Rec."Proktek Order No." := Fact."Order No.";
        Rec."Display Name" := CopyStr(StrSubstNo('Факт №%1 · Production ID %2', FactNo, Fact."Production ID"), 1, 250);
        Rec."Quantity Known" := TryReadProducedQuantity(Fact, Qty);
        if Rec."Quantity Known" then begin
            Rec."Actual Quantity M3" := Qty;
            Rec."Actual Display" := Format(Qty);
        end else
            Rec."Actual Display" := 'Невідомо';
        if Fact."Planned Quantity M3" > 0 then begin
            Rec."Planned Quantity M3" := Fact."Planned Quantity M3";
            Rec."Plan Display" := Format(Fact."Planned Quantity M3");
        end else
            Rec."Plan Display" := '—';
        Rec.Insert();

        // Current canonical model: one Proktek production UUID = one concrete party.
        // This remains a party even if only one physical mixing cycle was required.
        Rec.Init();
        NextEntryNo += 1;
        Rec."Entry No." := NextEntryNo;
        Rec."Node Type" := Rec."Node Type"::Party;
        Rec."Link State" := State;
        Rec.Indentation := 2;
        Rec."Fact Entry No." := Fact."Entry No.";
        Rec."Prod. Request Entry No." := Fact."Prod. Request Entry No.";
        Rec."Production Date/Time" := Fact."Production Date/Time";
        Rec."Truck Plate" := CopyStr(Fact."Truck Plate", 1, MaxStrLen(Rec."Truck Plate"));
        Rec."Item No." := Fact."Item No.";
        Rec."Proktek Order No." := Fact."Order No.";
        Rec."Display Name" := CopyStr(StrSubstNo('Партія №1 · %1 · Production ID %2', Fact."Truck Plate", Fact."Production ID"), 1, 250);
        Rec."Quantity Known" := TryReadProducedQuantity(Fact, Qty);
        if Rec."Quantity Known" then begin
            Rec."Actual Quantity M3" := Qty;
            Rec."Actual Display" := Format(Qty);
        end else
            Rec."Actual Display" := 'Невідомо';
        if Fact."Planned Quantity M3" > 0 then begin
            Rec."Planned Quantity M3" := Fact."Planned Quantity M3";
            Rec."Plan Display" := Format(Fact."Planned Quantity M3");
        end else
            Rec."Plan Display" := '—';
        Rec.Insert();
    end;

    local procedure TryReadProducedQuantity(Fact: Record "SI Prok Production Fact"; var Quantity: Decimal): Boolean
    begin
        Quantity := Fact."Produced Quantity M3";
        // A zero without verification is unknown, not an actual produced zero.
        exit((Quantity > 0) or ((Quantity = 0) and
            (Fact."Verification Status" = Fact."Verification Status"::Verified)));
    end;

    local procedure OpenCurrentRecord()
    var
        SourceRequest: Record "SI Supply Req Header";
        ProdRequest: Record "SI Concrete Prod Request";
        Fact: Record "SI Prok Production Fact";
    begin
        case Rec."Node Type" of
            Rec."Node Type"::Request:
                case Rec."Request Scope" of
                    Rec."Request Scope"::SupplyRequest:
                        if SourceRequest.Get(Rec."Source No.") then
                            Page.Run(Page::"SI Supply Req Card", SourceRequest);
                    Rec."Request Scope"::ProductionRequest:
                        if ProdRequest.Get(Rec."Prod. Request Entry No.") then
                            Page.Run(Page::"SI Concrete Prod Req Card", ProdRequest);
                end;
            Rec."Node Type"::Fact, Rec."Node Type"::Party:
                if Fact.Get(Rec."Fact Entry No.") then
                    Page.Run(Page::"SI Prok Production Fact Card", Fact);
        end;
    end;

    var
        CanExport: Boolean;
        NextEntryNo: Integer;
}
