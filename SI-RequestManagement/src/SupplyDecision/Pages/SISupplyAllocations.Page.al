page 52045 "SI Supply Allocations"
{
    PageType = ListPart;
    SourceTable = "SI Supply Allocation";
    ApplicationArea = All;
    Caption = 'Способи забезпечення';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Allocations)
            {
                Editable = IsPageEditable;

                field("Supply Method"; Rec."Supply Method")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Production Date"; Rec."Production Date")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Created Document Type"; Rec."Created Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created Document No."; Rec."Created Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        if Rec."Created Document No." = '' then
                            exit;

                        case Rec."Created Document Type" of
                            Rec."Created Document Type"::"Production Order":
                                begin
                                    ProdOrder.Get(
                                        ProdOrder.Status::"Firm Planned",
                                        Rec."Created Document No.");
                                    Page.Run(Page::"Firm Planned Prod. Order", ProdOrder);
                                end;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Supply Method" := Rec."Supply Method"::Production;
    end;

    trigger OnAfterGetRecord()
    begin
        SetPageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPageState();
    end;

    local procedure SetPageState()
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        IsPageEditable := false;

        if DecisionHeader.Get(Rec."Document No.") then
            IsPageEditable :=
                DecisionHeader.Status = DecisionHeader.Status::Draft;
    end;

    var
        IsPageEditable: Boolean;
}
