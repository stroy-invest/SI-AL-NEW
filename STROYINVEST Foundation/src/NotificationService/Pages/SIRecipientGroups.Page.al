page 50252 "SI Recipient Groups"
{
    Caption = 'Групи отримувачів';
    PageType = List;
    SourceTable = "SI Recipient Group";
    UsageCategory = Administration;
    ApplicationArea = All;
    CardPageId = "SI Recipient Group Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає унікальний код групи отримувачів.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис групи отримувачів.';
                }

                field("Resolver Type"; Rec."Resolver Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає спосіб визначення отримувачів для цієї групи.';
                }

                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                    Caption = 'Провайдер / користувач';
                    ToolTip = 'Визначає код провайдера або користувача залежно від вибраного типу визначення отримувачів.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupProvider(Text));
                    end;
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи може група використовуватися для створення повідомлень.';
                }

                field("Include Inactive Users"; Rec."Include Inactive Users")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи потрібно включати неактивних користувачів до результату визначення отримувачів.';
                }

                field("Remove Duplicates"; Rec."Remove Duplicates")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи потрібно видаляти дублікати отримувачів.';
                }
            }
        }
    }

    local procedure LookupProvider(var SelectedText: Text): Boolean
    var
        UserRecord: Record User;
    begin
        case Rec."Resolver Type" of
            Rec."Resolver Type"::ExplicitUser:
                begin
                    if Page.RunModal(
                        Page::Users,
                        UserRecord) <> Action::LookupOK
                    then
                        exit(false);

                    Rec.Validate(
                        "Provider Code",
                        CopyStr(
                            UserRecord."User Name",
                            1,
                            MaxStrLen(Rec."Provider Code")));

                    SelectedText := Rec."Provider Code";
                    exit(true);
                end;
        end;

        exit(false);
    end;
}