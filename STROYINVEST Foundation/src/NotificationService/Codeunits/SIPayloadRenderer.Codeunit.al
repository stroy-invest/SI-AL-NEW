codeunit 50236 "SI Payload Renderer"
{
    procedure Render(
        TemplateText: Text;
        Payload: JsonObject): Text
    var
        RenderedText: Text;
        TokenName: Text;
        TokenValue: Text;
        TokenStartPosition: Integer;
        TokenEndPosition: Integer;
        PlaceholderLength: Integer;
    begin
        RenderedText := TemplateText;

        if RenderedText = '' then
            exit('');

        TokenStartPosition :=
            StrPos(
                RenderedText,
                TokenStartTxt);

        while TokenStartPosition > 0 do begin
            TokenEndPosition :=
                FindTokenEndPosition(
                    RenderedText,
                    TokenStartPosition);

            if TokenEndPosition = 0 then
                exit(RenderedText);

            TokenName :=
                ExtractTokenName(
                    RenderedText,
                    TokenStartPosition,
                    TokenEndPosition);

            if TryGetPayloadValue(
                Payload,
                TokenName,
                TokenValue)
            then begin
                PlaceholderLength :=
                    TokenEndPosition -
                    TokenStartPosition +
                    StrLen(TokenEndTxt);

                RenderedText :=
                    ReplacePlaceholder(
                        RenderedText,
                        TokenStartPosition,
                        PlaceholderLength,
                        TokenValue);
            end else
                TokenStartPosition :=
                    TokenEndPosition +
                    StrLen(TokenEndTxt);

            TokenStartPosition :=
                FindNextTokenStart(
                    RenderedText,
                    TokenStartPosition);
        end;

        exit(RenderedText);
    end;

    local procedure FindTokenEndPosition(
        TemplateText: Text;
        TokenStartPosition: Integer): Integer
    var
        RemainingText: Text;
        RelativeEndPosition: Integer;
    begin
        RemainingText :=
            CopyStr(
                TemplateText,
                TokenStartPosition + StrLen(TokenStartTxt));

        RelativeEndPosition :=
            StrPos(
                RemainingText,
                TokenEndTxt);

        if RelativeEndPosition = 0 then
            exit(0);

        exit(
            TokenStartPosition +
            StrLen(TokenStartTxt) +
            RelativeEndPosition -
            1);
    end;

    local procedure ExtractTokenName(
        TemplateText: Text;
        TokenStartPosition: Integer;
        TokenEndPosition: Integer): Text
    var
        TokenLength: Integer;
    begin
        TokenLength :=
            TokenEndPosition -
            TokenStartPosition -
            StrLen(TokenStartTxt);

        exit(
            DelChr(
                CopyStr(
                    TemplateText,
                    TokenStartPosition + StrLen(TokenStartTxt),
                    TokenLength),
                '<>',
                ' '));
    end;

    local procedure TryGetPayloadValue(
        Payload: JsonObject;
        TokenName: Text;
        var TokenValue: Text): Boolean
    var
        PayloadToken: JsonToken;
        PayloadValue: JsonValue;
    begin
        Clear(TokenValue);

        if TokenName = '' then
            exit(false);

        if not Payload.Get(
            TokenName,
            PayloadToken)
        then
            exit(false);

        if not PayloadToken.IsValue() then
            exit(false);

        PayloadValue :=
            PayloadToken.AsValue();

        if PayloadValue.IsNull() then begin
            TokenValue := '';
            exit(true);
        end;

        TokenValue :=
            PayloadValue.AsText();

        exit(true);
    end;

    local procedure ReplacePlaceholder(
        TemplateText: Text;
        TokenStartPosition: Integer;
        PlaceholderLength: Integer;
        ReplacementValue: Text): Text
    var
        PrefixText: Text;
        SuffixText: Text;
    begin
        if TokenStartPosition > 1 then
            PrefixText :=
                CopyStr(
                    TemplateText,
                    1,
                    TokenStartPosition - 1);

        SuffixText :=
            CopyStr(
                TemplateText,
                TokenStartPosition + PlaceholderLength);

        exit(
            PrefixText +
            ReplacementValue +
            SuffixText);
    end;

    local procedure FindNextTokenStart(
        TemplateText: Text;
        SearchFromPosition: Integer): Integer
    var
        RemainingText: Text;
        RelativePosition: Integer;
    begin
        if SearchFromPosition <= 0 then
            SearchFromPosition := 1;

        if SearchFromPosition > StrLen(TemplateText) then
            exit(0);

        RemainingText :=
            CopyStr(
                TemplateText,
                SearchFromPosition);

        RelativePosition :=
            StrPos(
                RemainingText,
                TokenStartTxt);

        if RelativePosition = 0 then
            exit(0);

        exit(
            SearchFromPosition +
            RelativePosition -
            1);
    end;

    var
        TokenStartTxt:
            Label '{{',
            Locked = true;

        TokenEndTxt:
            Label '}}',
            Locked = true;
}