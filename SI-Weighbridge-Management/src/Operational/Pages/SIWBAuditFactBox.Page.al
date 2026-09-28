page 59105 "SI WB Audit FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Weighbridge Document";

    Caption = 'Аудит';

    layout
    {
        area(Content)
        {
            field("Created At"; Rec."Created At")
            {
                ApplicationArea = All;
                Caption = 'Створено';
                Editable = false;
            }

            field(CreatedByUserName; CreatedByUserName)
            {
                ApplicationArea = All;
                Caption = 'Створено користувачем';
                Editable = false;
            }

            field("Modified At"; Rec."Modified At")
            {
                ApplicationArea = All;
                Caption = 'Змінено';
                Editable = false;
            }

            field(ModifiedByUserName; ModifiedByUserName)
            {
                ApplicationArea = All;
                Caption = 'Змінено користувачем';
                Editable = false;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadUserNames();
    end;

    local procedure LoadUserNames()
    begin
        CreatedByUserName :=
            ResolveUserName(Rec."Created By");

        ModifiedByUserName :=
            ResolveUserName(Rec."Modified By");
    end;

    local procedure ResolveUserName(
        UserSecurityID: Guid): Text[100]
    var
        User: Record User;
        EmptyGuid: Guid;
    begin
        if UserSecurityID = EmptyGuid then
            exit('');

        User.Reset();
        User.SetRange(
            "User Security ID",
            UserSecurityID);

        if User.FindFirst() then
            exit(
                CopyStr(
                    User."User Name",
                    1,
                    100));

        // Fallback: якщо відповідного User уже немає,
        // GUID усе одно не втрачаємо для діагностики.
        exit(
            CopyStr(
                Format(UserSecurityID),
                1,
                100));
    end;

    var
        CreatedByUserName: Text[100];
        ModifiedByUserName: Text[100];
}