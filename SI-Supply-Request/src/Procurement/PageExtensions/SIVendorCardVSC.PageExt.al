pageextension 61041 "SI Vendor Card VSC" extends "Vendor Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIConfigureSupplyCapabilities)
            {
                ApplicationArea = All;
                Caption = 'Налаштувати канали постачання';
                ToolTip = 'Вибрати категорії товарів і налаштувати канали та умови постачання для цього постачальника.';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                trigger OnAction()
                var Wizard: Page "SI VSC Wizard";
                begin
                    Rec.TestField("No.");
                    Wizard.SetVendor(Rec."No.");
                    Wizard.RunModal();
                end;
            }
        }
    }
}
