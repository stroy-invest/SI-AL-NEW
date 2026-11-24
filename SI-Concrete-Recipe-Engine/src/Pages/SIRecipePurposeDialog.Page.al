namespace STROYINVEST.ConcreteRecipeEngine;

page 62116 "SI Recipe Purpose Dialog"
{
    PageType = StandardDialog;
    Caption = 'Виберіть призначення рецептури';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Purpose; Purpose)
            {
                ApplicationArea = All;
                Caption = 'Призначення рецептури';
                trigger OnValidate()
                begin
                    IsTechnological := Purpose = Purpose::Technological;
                    if not IsTechnological then
                        Clear(TechDescription);
                    CurrPage.Update(false);
                end;
            }
            field(TechDescription; TechDescription)
            {
                ApplicationArea = All;
                Caption = 'Опис технологічної рецептури';
                Enabled = IsTechnological;
                ToolTip = 'Заповнюється лише для технологічної рецептури.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = Action::OK) and (Purpose = Purpose::Technological) then
            if DelChr(TechDescription, '<>', ' ') = '' then
                Error('Вкажіть опис технологічної рецептури.');
        exit(true);
    end;

    procedure GetSelection(var SelectedPurpose: Enum "SI Recipe Purpose"; var Description: Text[100])
    begin
        SelectedPurpose := Purpose;
        Description := TechDescription;
    end;

    var
        Purpose: Enum "SI Recipe Purpose";
        TechDescription: Text[100];
        IsTechnological: Boolean;
}
