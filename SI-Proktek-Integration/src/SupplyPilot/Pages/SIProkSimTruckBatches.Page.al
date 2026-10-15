page 57096 "SI Prok Sim Truck Batches"
{
    PageType = List;
    SourceTable = "SI Prok Sim Truck Batch";
    Caption = 'Імітація виробництва за автоміксерами';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Batches)
            {
                field("Supply Request No."; Rec."Supply Request No.") { ApplicationArea = All; }
                field("Truck No."; Rec."Truck No.") { ApplicationArea = All; }
                field("Truck Code"; Rec."Truck Code") { ApplicationArea = All; }
                field("Truck Capacity M3"; Rec."Truck Capacity M3") { ApplicationArea = All; }
                field("Mix Count"; Rec."Mix Count") { ApplicationArea = All; }
                field("Produced M3"; Rec."Produced M3") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(MaterialAudit)
            {
                Caption = 'План / факт матеріалів';
                ApplicationArea = All;
                Image = AnalysisView;
                trigger OnAction()
                var
                    AuditPage: Page "SI Prok Material Audit";
                begin
                    AuditPage.SetOrderUuid(Rec."Order UUID");
                    AuditPage.RunModal();
                end;
            }
            action(ViewMixes)
            {
                Caption = 'Замiси автоміксера';
                ApplicationArea = All;
                Image = ViewDetails;
                trigger OnAction()
                var
                    Fact: Record "SI Prok Production Fact";
                begin
                    Fact.SetRange("Order UUID", Rec."Order UUID");
                    Fact.SetRange("Truck Code", Rec."Truck Code");
                    Fact.SetRange("Simulation", true);
                    Page.Run(Page::"SI Prok Production Facts", Fact);
                end;
            }
        }
    }
}
