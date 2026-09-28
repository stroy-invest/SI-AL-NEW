page 50253 "SI Recipient Group Card"
{
    Caption = 'Група отримувачів';
    PageType = Card;
    SourceTable = "SI Recipient Group";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає унікальний код групи отримувачів.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає зрозумілий опис групи отримувачів.';
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи може група використовуватися для створення повідомлень.';
                }
            }

            group(Resolution)
            {
                Caption = 'Визначення отримувачів';

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

                field("Include Inactive Users"; Rec."Include Inactive Users")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи потрібно включати неактивних користувачів.';
                }

                field("Remove Duplicates"; Rec."Remove Duplicates")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи потрібно видаляти дублікати отримувачів.';
                }
            }

            group(Additional)
            {
                Caption = 'Додатково';

                field(Notes; Rec.Notes)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає примітки щодо призначення та використання групи отримувачів.';
                }
            }

            group(Audit)
            {
                Caption = 'Аудит';

                field("Last Modified At"; Rec."Last Modified At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час останньої зміни запису.';
                }

                field("Last Modified By"; Rec."Last Modified By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який останнім змінив запис.';
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