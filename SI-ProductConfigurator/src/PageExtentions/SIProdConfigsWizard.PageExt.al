pageextension 53000 "SI Prod. Configs Wiz. Ext"
    extends "SI Product Configs."
{
    actions
    {
        addfirst(Processing)
        {
            action(CreateWithWizard)
            {
                ApplicationArea = All;
                Caption = 'Створити через майстер';
                Image = NewDocument;
                ToolTip = 'Відкриває покроковий майстер створення конкретної конфігурації продукту.';

                trigger OnAction()
                var
                    ProductConfig: Record "SI Product Config.";
                    ProductConfigWizard: Page "SI Product Config. Wizard";
                    CreatedConfigurationNo: Code[20];
                begin
                    Clear(ProductConfigWizard);
                    ProductConfigWizard.RunModal();
                    CreatedConfigurationNo :=
                        ProductConfigWizard.GetCreatedConfigurationNo();

                    if CreatedConfigurationNo = '' then
                        exit;

                    ProductConfig.Get(CreatedConfigurationNo);

                    // The wizard creates the configuration while this page
                    // remains open. Re-render the hierarchy immediately so the
                    // new node is visible without browser F5.
                    RefreshConfigurationTree();

                    // Open the created configuration modally. If the user makes
                    // further changes on the card, refresh once more on return.
                    Page.RunModal(Page::"SI Product Config. Card", ProductConfig);
                    RefreshConfigurationTree();
                end;
            }
        }

        addfirst(Promoted)
        {
            actionref(CreateWithWizardPromoted; CreateWithWizard)
            {
            }
        }
    }
}
