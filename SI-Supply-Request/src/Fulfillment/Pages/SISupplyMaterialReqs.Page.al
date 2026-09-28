page 61018 "SI Supply Material Reqs."
{
    PageType = List;
    SourceTable = "SI Supply Material Req.";
    Caption = 'Потреба в матеріалах';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Quantity per"; Rec."Quantity per") { ApplicationArea = All; }
                field("Required Quantity"; Rec."Required Quantity") { ApplicationArea = All; }
                field("Available Quantity"; Rec."Available Quantity") { ApplicationArea = All; }
                field("Shortage Quantity"; Rec."Shortage Quantity") { ApplicationArea = All; }
                field("Selected Vendor Name"; Rec."Selected Vendor Name") { ApplicationArea = All; }
                field("Prepared for Procurement"; Rec."Prepared for Procurement") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Revision No."; Rec."Revision No.") { ApplicationArea = All; }
                field("Checked At"; Rec."Checked At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectVendor)
            {
                ApplicationArea = All;
                Caption = 'Вибрати постачальника';
                Image = Vendor;
                Enabled = Rec."Shortage Quantity" > 0;
                trigger OnAction()
                var
                    ProcurementMgt: Codeunit "SI Procurement Prep. Mgt.";
                begin
                    ProcurementMgt.SelectVendor(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(AddToProcurement)
            {
                ApplicationArea = All;
                Caption = 'Додати до закупівлі';
                Image = Add;
                Enabled = (Rec."Shortage Quantity" > 0) and (Rec."Selected Vendor No." <> '') and (Rec."Procurement Batch No." = '');
                trigger OnAction()
                var
                    ProcurementMgt: Codeunit "SI Procurement Prep. Mgt.";
                begin
                    ProcurementMgt.AddToProcurement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenProcurementPreview)
            {
                ApplicationArea = All;
                Caption = 'Підготовка закупівлі';
                Image = View;
                trigger OnAction()
                var
                    ProcurementMgt: Codeunit "SI Procurement Prep. Mgt.";
                begin
                    ProcurementMgt.OpenDraftPreview();
                end;
            }
        }
    }

}
