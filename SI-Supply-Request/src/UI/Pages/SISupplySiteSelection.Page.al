page 61030 "SI Supply Site Selection"
{
    PageType = StandardDialog;
    SourceTable = "SI Supply Request Site";
    Caption = 'Будівельні майданчики заявки';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Sites)
            {
                ShowCaption = false;

                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрати';
                }

                field("Site Name"; Rec."Site Name")
                {
                    ApplicationArea = All;
                    Caption = 'Будівельний майданчик';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if RequestNoContext = '' then
            Error('Не визначено заявку для вибору будівельних майданчиків.');

        Rec.SetRange("Request No.", RequestNoContext);
        if Rec.IsEmpty() then
            Error('Для заявки %1 не сформовано перелік будівельних майданчиків.', RequestNoContext);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RequestSiteMgt: Codeunit "SI Supply Request Site Mgt.";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        CurrPage.SaveRecord();
        RequestSiteMgt.EnsureSelectedSiteExists(RequestNoContext);
        exit(true);
    end;

    procedure SetRequestNo(RequestNo: Code[20])
    begin
        RequestNoContext := RequestNo;
    end;

    var
        RequestNoContext: Code[20];
}
