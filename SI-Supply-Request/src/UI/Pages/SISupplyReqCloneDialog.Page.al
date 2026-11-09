page 61065 "SI Supply Req Clone Dialog"
{
    PageType = StandardDialog;
    Caption = 'Клонувати заявку';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Parameters)
            {
                Caption = 'Нова заявка';
                field(SourceRequestNo; SourceRequestNo)
                {
                    ApplicationArea = All;
                    Caption = 'Вихідна заявка';
                    Editable = false;
                }
                field(NewRequiredAt; NewRequiredAt)
                {
                    ApplicationArea = All;
                    Caption = 'Нова дата потреби';
                    ShowMandatory = true;
                    ToolTip = 'Дата та час мають бути пізнішими за попередню дату потреби й поточний момент.';
                }
                field(CloneReason; CloneReason)
                {
                    ApplicationArea = All;
                    Caption = 'Причина повторного створення';
                    ShowMandatory = true;
                    MultiLine = true;
                }
            }
        }
    }

    procedure SetSourceRequest(RequestNo: Code[20])
    begin
        SourceRequestNo := RequestNo;
    end;

    procedure GetValues(var RequiredAt: DateTime; var Reason: Text[250])
    begin
        RequiredAt := NewRequiredAt;
        Reason := CloneReason;
    end;

    var
        SourceRequestNo: Code[20];
        NewRequiredAt: DateTime;
        CloneReason: Text[250];
}
