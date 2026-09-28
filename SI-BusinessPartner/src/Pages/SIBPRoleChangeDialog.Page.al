page 54033 "SI BP Role Change Dialog"
{
    PageType = StandardDialog;
    Caption = 'Зміна стану ролі';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Причина зміни';

                field(ReasonField; ReasonValue)
                {
                    ApplicationArea = All;
                    Caption = 'Причина';
                }

                field(CommentField; CommentValue)
                {
                    ApplicationArea = All;
                    Caption = 'Коментар';
                    MultiLine = true;
                }
            }
        }
    }

    procedure GetReason(): Text
    begin
        exit(ReasonValue);
    end;

    procedure GetComment(): Text
    begin
        exit(CommentValue);
    end;

    var
        ReasonValue: Text[100];
        CommentValue: Text[250];
}