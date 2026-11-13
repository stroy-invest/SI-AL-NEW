page 57198 "SI Prok Shipment Links FB"
{
    PageType = CardPart;
    SourceTable = "SI Prok Shipment";
    Caption = 'Службові зв’язки';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(Links)
            {
                Caption = 'Зв’язки';
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Production Fact Entry No."; Rec."Production Fact Entry No.") { ApplicationArea = All; }
                field("Prod. Request Entry No."; Rec."Prod. Request Entry No.") { ApplicationArea = All; }
                field("Driver UUID"; Rec."Driver UUID") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("Supply Decision No."; Rec."Supply Decision No.") { ApplicationArea = All; }
                field("Supply Decision Line No."; Rec."Supply Decision Line No.") { ApplicationArea = All; }
                field("Supply Allocation Line No."; Rec."Supply Allocation Line No.") { ApplicationArea = All; }
                field("Supply Allocation System ID"; Rec."Supply Allocation System ID") { ApplicationArea = All; }
                field("Allocation Binding Status"; Rec."Allocation Binding Status") { ApplicationArea = All; }
                field("Delivery Project No."; Rec."Delivery Project No.") { ApplicationArea = All; }
                field("Delivery Site Code"; Rec."Delivery Site Code") { ApplicationArea = All; }
                field("Shipped By Employee No."; Rec."Shipped By Employee No.") { ApplicationArea = All; }
                field("Received By Employee No."; Rec."Received By Employee No.") { ApplicationArea = All; }
                field("Document Snapshot Status"; Rec."Document Snapshot Status") { ApplicationArea = All; }
                field("Snapshot Created At"; Rec."Snapshot Created At") { ApplicationArea = All; }
            }
        }
    }
}
