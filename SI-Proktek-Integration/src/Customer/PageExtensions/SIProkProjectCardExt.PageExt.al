pageextension 57020 "SI Prok Project Card Ext." extends "Job Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncProjectCustomerToProktek)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати клієнта з Proktek';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CustomerSync: Codeunit "SI Prok Customer Sync";
                    Mapping: Record "SI Prok Entity Mapping";
                begin
                    CurrPage.SaveRecord();

                    CustomerSync.SyncProjectCustomer(Rec, Mapping);

                    if IsNullGuid(Mapping."Proktek UUID") then
                        exit;

                    Message(
                        'Інтеграційний клієнт проєкту синхронізовано з Proktek.\' +
                        'BC Customer: %1\' +
                        'Proktek UUID: %2\' +
                        'Підключення: %3',
                        Mapping."BC No.",
                        Mapping."Proktek UUID",
                        Mapping."Connection Code");
                end;
            }

            action(SyncProjectSiteToProktek)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати будмайданчик з Proktek';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SiteSync: Codeunit "SI Prok Site Sync";
                    Mapping: Record "SI Prok Entity Mapping";
                begin
                    CurrPage.SaveRecord();

                    SiteSync.SyncProjectSite(Rec, Mapping);

                    if IsNullGuid(Mapping."Proktek UUID") then
                        exit;

                    Message(
                        'Будмайданчик проєкту синхронізовано з Proktek.\' +
                        'BC Project: %1\' +
                        'Proktek UUID: %2\' +
                        'Підключення: %3',
                        Mapping."BC No.",
                        Mapping."Proktek UUID",
                        Mapping."Connection Code");
                end;
            }

            action(ReadProjectCustomerFromProktek)
            {
                ApplicationArea = All;
                Caption = 'Прочитати клієнта з Proktek';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CustomerRead: Codeunit "SI Prok Customer Read";
                begin
                    CurrPage.SaveRecord();
                    CustomerRead.ReadProjectCustomer(Rec);
                end;
            }
        }
    }

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        NullGuid: Guid;
    begin
        exit(Value = NullGuid);
    end;
}
