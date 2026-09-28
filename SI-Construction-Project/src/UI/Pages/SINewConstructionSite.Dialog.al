page 60022 "SI New Construction Site"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Новий будівельний майданчик';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(SiteName; SiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ToolTip = 'Вкажіть бізнес-назву нового будівельного майданчика.';
                }
                field(SiteDescription; SiteDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    ToolTip = 'Необов''язковий розширений опис будівельного майданчика.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if SiteName = '' then
                Error('Вкажіть назву будівельного майданчика.');

        exit(true);
    end;

    procedure GetSiteName(): Text[100]
    begin
        exit(SiteName);
    end;

    procedure GetSiteDescription(): Text[250]
    begin
        exit(SiteDescription);
    end;

    var
        SiteName: Text[100];
        SiteDescription: Text[250];
}
