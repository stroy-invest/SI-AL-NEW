controladdin "SI Foreign Bank Tree"
{
    RequestedHeight = 600;
    RequestedWidth = 1200;
    MinimumHeight = 350;
    MinimumWidth = 800;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'src/ControlAddIns/SIForeignBankTree.js';

    StartupScript =
        'src/ControlAddIns/SIForeignBankTreeStartup.js';

    event ControlReady();
    event BankSelected(BankId: Text);
    event BankOpenRequested(BankId: Text);

    procedure RenderBanks(BankJson: Text);
    procedure SelectBank(BankId: Text);
    procedure ExpandAll();
    procedure CollapseAll();
    procedure SetLoading(IsLoading: Boolean);
}
