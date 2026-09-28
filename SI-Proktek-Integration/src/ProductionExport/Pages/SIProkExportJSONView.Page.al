page 57082 "SI Prok Export JSON View"
{
    PageType = Card;
    SourceTable = "SI Prok Production Export";
    Caption = 'Перегляд JSON експорту Proktek';
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Експорт';

                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                }
                field("Date From"; Rec."Date From")
                {
                    ApplicationArea = All;
                }
                field("Date To"; Rec."Date To")
                {
                    ApplicationArea = All;
                }
            }

            group(JsonGroup)
            {
                Caption = 'JSON';

                field(JsonText; JsonText)
                {
                    ApplicationArea = All;
                    Caption = 'Вміст JSON';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveJsonToFile)
            {
                ApplicationArea = All;
                Caption = 'Зберегти JSON у файл';
                Image = Save;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    DownloadFormattedJson();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        JsonText := FormatJson(Rec.GetPayload());
    end;

    local procedure DownloadFormattedJson()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        DownloadName: Text;
    begin
        if JsonText = '' then
            Error('Для цього експорту відсутній JSON.');

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        DownloadName := Rec."File Name";
        if DownloadName = '' then
            DownloadName := StrSubstNo('Proktek_Production_Export_%1.json', Rec."Entry No.");

        DownloadFromStream(InStr, '', '', 'JSON files (*.json)|*.json', DownloadName);
    end;

    local procedure FormatJson(RawJson: Text): Text
    var
        ResultBuilder: TextBuilder;
        IndentLevel: Integer;
        Index: Integer;
        JsonChar: Char;
        IsInString: Boolean;
        IsEscaped: Boolean;
    begin
        if RawJson = '' then
            exit('');

        for Index := 1 to StrLen(RawJson) do begin
            JsonChar := RawJson[Index];

            if IsInString then begin
                ResultBuilder.Append(Format(JsonChar));

                if IsEscaped then
                    IsEscaped := false
                else
                    if JsonChar = '\' then
                        IsEscaped := true
                    else
                        if JsonChar = '"' then
                            IsInString := false;

                continue;
            end;

            case JsonChar of
                '"':
                    begin
                        IsInString := true;
                        ResultBuilder.Append(Format(JsonChar));
                    end;
                '{', '[':
                    begin
                        ResultBuilder.Append(Format(JsonChar));
                        ResultBuilder.AppendLine();
                        IndentLevel += 1;
                        AppendIndent(ResultBuilder, IndentLevel);
                    end;
                '}', ']':
                    begin
                        ResultBuilder.AppendLine();
                        if IndentLevel > 0 then
                            IndentLevel -= 1;
                        AppendIndent(ResultBuilder, IndentLevel);
                        ResultBuilder.Append(Format(JsonChar));
                    end;
                ',':
                    begin
                        ResultBuilder.Append(',');
                        ResultBuilder.AppendLine();
                        AppendIndent(ResultBuilder, IndentLevel);
                    end;
                ':':
                    ResultBuilder.Append(': ');
                ' ':
                    ;
                else
                    ResultBuilder.Append(Format(JsonChar));
            end;
        end;

        exit(ResultBuilder.ToText());
    end;

    local procedure AppendIndent(var Builder: TextBuilder; IndentLevel: Integer)
    var
        IndentIndex: Integer;
    begin
        for IndentIndex := 1 to IndentLevel do
            Builder.Append('  ');
    end;

    var
        JsonText: Text;
}
