page 54013 "SI Foreign Bank List"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Закордонні банки';

    layout
    {
        area(Content)
        {
            usercontrol(ForeignBankTree; "SI Foreign Bank Tree")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    LoadForeignBanks();
                end;

                trigger BankSelected(BankId: Text)
                begin
                    SelectedBankId := CopyStr(BankId, 1, MaxStrLen(SelectedBankId));
                end;

                trigger BankOpenRequested(BankId: Text)
                var
                    ForeignBank: Record "SI Foreign Bank";
                    BankIdCode: Code[10];
                begin
                    BankIdCode := CopyStr(BankId, 1, MaxStrLen(BankIdCode));
                    if BankIdCode = '' then
                        exit;

                    if not ForeignBank.Get(BankIdCode) then
                        exit;

                    Page.Run(Page::"SI Foreign Bank Card", ForeignBank);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Оновити';
                Image = Refresh;
                ToolTip = 'Refreshes the foreign bank hierarchy.';

                trigger OnAction()
                begin
                    LoadForeignBanks();
                end;
            }
        }
    }

    var
        SelectedBankId: Code[10];

    local procedure LoadForeignBanks()
    begin
        CurrPage.ForeignBankTree.SetLoading(true);
        CurrPage.ForeignBankTree.RenderBanks(GetForeignBankJson());
    end;

    local procedure GetForeignBankJson(): Text
    var
        ForeignBank: Record "SI Foreign Bank";
        CountryRegion: Record "Country/Region";
        Banks: JsonArray;
        Bank: JsonObject;
        JsonText: Text;
        CountryCode: Code[10];
        CountryName: Text;
        LastCountryCode: Code[10];
    begin
        ForeignBank.SetCurrentKey("Country Code");

        if ForeignBank.FindSet(false) then
            repeat
                CountryCode := ForeignBank."Country Code";

                // The record set is sorted by Country Code, so resolve the country
                // only when the value changes instead of doing one GET per bank.
                if CountryCode <> LastCountryCode then begin
                    LastCountryCode := CountryCode;
                    CountryName := CountryCode;

                    if (CountryCode <> '') and CountryRegion.Get(CountryCode) then
                        CountryName := CountryRegion.Name;
                end;

                Clear(Bank);
                Bank.Add('id', ForeignBank.Id);
                Bank.Add('countryCode', CountryCode);
                Bank.Add('countryName', CountryName);
                Bank.Add('swift', ForeignBank.SWIFT);
                Bank.Add('name', ForeignBank.Name);
                Bank.Add('city', ForeignBank."City Name");
                Bank.Add('isActive', ForeignBank."Is Active");
                Banks.Add(Bank);
            until ForeignBank.Next() = 0;

        Banks.WriteTo(JsonText);
        exit(JsonText);
    end;
}
