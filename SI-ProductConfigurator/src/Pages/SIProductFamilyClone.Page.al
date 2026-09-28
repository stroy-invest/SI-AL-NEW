page 53035 "SI Product Family Clone"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Клонування сімейства';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Нове сімейство';

                field(SourceFamilyCode; SourceFamilyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Оригінальне сімейство';
                    Editable = false;
                    ToolTip = 'Визначає сімейство, на основі якого створюється клон.';
                }

                field(NewFamilyCode; NewFamilyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код нового сімейства';
                    ShowMandatory = true;
                    ToolTip = 'Вкажіть унікальний код нового сімейства.';
                }

                field(NewDescription; NewDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва нового сімейства';
                    ShowMandatory = true;
                    ToolTip = 'Вкажіть назву нового сімейства.';
                }
            }
        }
    }

    procedure SetSourceFamily(Family: Record "SI Product Family")
    begin
        SourceFamilyCode := Family.Code;
    end;

    procedure GetNewFamilyCode(): Code[30]
    begin
        exit(NewFamilyCode);
    end;

    procedure GetNewDescription(): Text[100]
    begin
        exit(NewDescription);
    end;

    var
        SourceFamilyCode: Code[30];
        NewFamilyCode: Code[30];
        NewDescription: Text[100];
}
