codeunit 50191 "SI Address Parser Mgt."
{
    procedure ParseAddress(
        AddressText: Text;
        CountryRegionCode: Code[20];
        Source: Code[50];
        SourceRecordNo: Code[50];
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary)
    begin
        Parse(
            AddressText,
            ParsedAddress);

        if not ParsedAddress."Parse Successful" then
            LogFailure(
                ParsedAddress,
                Source,
                SourceRecordNo);
    end;

    procedure Parse(
        AddressText: Text;
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary)
    var
        AddressFragments: List of [Text];
        AddressFragment: Text;
        NormalizedFragment: Text;
        ExtractedValue: Text;
        RecognizedFragmentCount: Integer;
    begin
        InitializeBuffer(ParsedAddress, AddressText);

        if AddressText.Trim() = '' then begin
            AddParseIssue(
                ParsedAddress,
                '',
                EmptyAddressMsg);

            FinalizeParsing(
                ParsedAddress,
                RecognizedFragmentCount);

            exit;
        end;

        AddressFragments := AddressText.Split(',');

        foreach AddressFragment in AddressFragments do begin
            NormalizedFragment := AddressFragment.Trim();

            if NormalizedFragment <> '' then begin
                Clear(ExtractedValue);

                if TryParseCountry(
                    NormalizedFragment,
                    ExtractedValue)
                then begin
                    SetParsedValue(
                        ParsedAddress."Country Name",
                        ExtractedValue,
                        CountryFieldNameLbl,
                        NormalizedFragment,
                        ParsedAddress);

                    RecognizedFragmentCount += 1;
                end else
                    if TryParsePostCode(
                        NormalizedFragment,
                        ExtractedValue)
                    then begin
                        SetParsedValue(
                            ParsedAddress."Post Code",
                            ExtractedValue,
                            PostCodeFieldNameLbl,
                            NormalizedFragment,
                            ParsedAddress);

                        RecognizedFragmentCount += 1;
                    end else
                        if TryParseRegion(
                            NormalizedFragment,
                            ExtractedValue)
                        then begin
                            SetParsedValue(
                                ParsedAddress."Region Name",
                                ExtractedValue,
                                RegionFieldNameLbl,
                                NormalizedFragment,
                                ParsedAddress);

                            RecognizedFragmentCount += 1;
                        end else
                            if TryParseDistrict(
                                NormalizedFragment,
                                ExtractedValue)
                            then begin
                                SetParsedValue(
                                    ParsedAddress."District Name",
                                    ExtractedValue,
                                    DistrictFieldNameLbl,
                                    NormalizedFragment,
                                    ParsedAddress);

                                RecognizedFragmentCount += 1;
                            end else
                                if TryParseCity(
                                    NormalizedFragment,
                                    ExtractedValue)
                                then begin
                                    SetParsedValue(
                                        ParsedAddress."City Name",
                                        ExtractedValue,
                                        CityFieldNameLbl,
                                        NormalizedFragment,
                                        ParsedAddress);

                                    RecognizedFragmentCount += 1;
                                end else
                                    if TryParseStreet(
                                        NormalizedFragment,
                                        ExtractedValue)
                                    then begin
                                        SetParsedValue(
                                            ParsedAddress.Street,
                                            ExtractedValue,
                                            StreetFieldNameLbl,
                                            NormalizedFragment,
                                            ParsedAddress);

                                        RecognizedFragmentCount += 1;
                                    end else
                                        if TryParseBuilding(
                                            NormalizedFragment,
                                            ExtractedValue)
                                        then begin
                                            SetParsedValue(
                                                ParsedAddress."Building No.",
                                                ExtractedValue,
                                                BuildingFieldNameLbl,
                                                NormalizedFragment,
                                                ParsedAddress);

                                            RecognizedFragmentCount += 1;
                                        end else
                                            if TryParseOffice(
                                                NormalizedFragment,
                                                ExtractedValue)
                                            then begin
                                                SetParsedValue(
                                                    ParsedAddress.Office,
                                                    ExtractedValue,
                                                    OfficeFieldNameLbl,
                                                    NormalizedFragment,
                                                    ParsedAddress);

                                                RecognizedFragmentCount += 1;
                                            end else
                                                if TryParseApartment(
                                                    NormalizedFragment,
                                                    ExtractedValue)
                                                then begin
                                                    SetParsedValue(
                                                        ParsedAddress.Apartment,
                                                        ExtractedValue,
                                                        ApartmentFieldNameLbl,
                                                        NormalizedFragment,
                                                        ParsedAddress);

                                                    RecognizedFragmentCount += 1;
                                                end else
                                                    AddParseIssue(
                                                        ParsedAddress,
                                                        NormalizedFragment,
                                                        StrSubstNo(
                                                            UnrecognizedFragmentMsg,
                                                            NormalizedFragment));
            end;
        end;

        FinalizeParsing(
            ParsedAddress,
            RecognizedFragmentCount);
    end;

    procedure LogFailure(
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary;
        Source: Code[50];
        SourceRecordNo: Code[50])
    var
        AddressParseLog: Record "SI Address Parse Log";
    begin
        if ParsedAddress."Parse Successful" then
            exit;

        AddressParseLog.Init();
        AddressParseLog."Created At" := CurrentDateTime();
        AddressParseLog."User ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(AddressParseLog."User ID"));

        AddressParseLog.Source := Source;
        AddressParseLog."Source Record No." := SourceRecordNo;

        AddressParseLog."Raw Address" :=
            ParsedAddress."Raw Address";

        AddressParseLog."Parse Message" :=
            ParsedAddress."Parse Message";

        AddressParseLog."Unrecognized Fragment" :=
            ParsedAddress."Unrecognized Fragment";

        AddressParseLog."Parsed Country Name" :=
            ParsedAddress."Country Name";

        AddressParseLog."Parsed Post Code" :=
            ParsedAddress."Post Code";

        AddressParseLog."Parsed Region Name" :=
            ParsedAddress."Region Name";

        AddressParseLog."Parsed District Name" :=
            ParsedAddress."District Name";

        AddressParseLog."Parsed City Name" :=
            ParsedAddress."City Name";

        AddressParseLog."Parsed Street" :=
            ParsedAddress.Street;

        AddressParseLog."Parsed Building No." :=
            ParsedAddress."Building No.";

        AddressParseLog."Parsed Office" :=
            ParsedAddress.Office;

        AddressParseLog."Parsed Apartment" :=
            ParsedAddress.Apartment;

        AddressParseLog.Insert(true);
    end;

    local procedure InitializeBuffer(
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary;
        AddressText: Text)
    begin
        ParsedAddress.Reset();
        ParsedAddress.DeleteAll();

        ParsedAddress.Init();
        ParsedAddress."Entry No." := 1;
        ParsedAddress."Raw Address" :=
            CopyStr(
                AddressText,
                1,
                MaxStrLen(ParsedAddress."Raw Address"));

        ParsedAddress."Parse Successful" := false;
        ParsedAddress.Insert();
    end;

    local procedure FinalizeParsing(
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary;
        RecognizedFragmentCount: Integer)
    begin
        if RecognizedFragmentCount = 0 then
            AddParseIssue(
                ParsedAddress,
                '',
                NoRecognizedFragmentsMsg);

        ParsedAddress."Parse Successful" :=
            (ParsedAddress."Parse Message" = '') and
            (ParsedAddress."Unrecognized Fragment" = '') and
            (RecognizedFragmentCount > 0);

        ParsedAddress.Modify();
    end;

    local procedure SetParsedValue(
        var TargetValue: Text[250];
        NewValue: Text;
        FieldName: Text;
        SourceFragment: Text;
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary)
    begin
        NewValue := NewValue.Trim();

        if NewValue = '' then begin
            AddParseIssue(
                ParsedAddress,
                SourceFragment,
                StrSubstNo(
                    EmptyComponentMsg,
                    FieldName,
                    SourceFragment));

            exit;
        end;

        if TargetValue <> '' then begin
            AddParseIssue(
                ParsedAddress,
                SourceFragment,
                StrSubstNo(
                    DuplicateComponentMsg,
                    FieldName,
                    TargetValue,
                    NewValue));

            exit;
        end;

        TargetValue :=
            CopyStr(
                NewValue,
                1,
                MaxStrLen(TargetValue));
    end;

    local procedure AddParseIssue(
        var ParsedAddress: Record "SI Parsed Address Buffer" temporary;
        Fragment: Text;
        MessageText: Text)
    begin
        AppendText(
            ParsedAddress."Parse Message",
            MessageText);

        if Fragment <> '' then
            AppendText(
                ParsedAddress."Unrecognized Fragment",
                Fragment);
    end;

    local procedure AppendText(
        var TargetText: Text[2048];
        ValueText: Text)
    var
        CombinedText: Text;
    begin
        if ValueText = '' then
            exit;

        if TargetText = '' then
            CombinedText := ValueText
        else
            CombinedText :=
                StrSubstNo(
                    '%1; %2',
                    TargetText,
                    ValueText);

        TargetText :=
            CopyStr(
                CombinedText,
                1,
                MaxStrLen(TargetText));
    end;

    local procedure TryParseCountry(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    var
        NormalizedValue: Text;
    begin
        NormalizedValue := LowerCase(Fragment.Trim());

        case NormalizedValue of
            'україна',
            'украина',
            'ukraine':
                begin
                    ParsedValue := Fragment.Trim();
                    exit(true);
                end;

            'ua':
                begin
                    ParsedValue := 'Україна';
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure TryParsePostCode(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    var
        CandidateValue: Text;
    begin
        CandidateValue := Fragment.Trim();

        if StrLen(CandidateValue) <> 5 then
            exit(false);

        if not ContainsDigitsOnly(CandidateValue) then
            exit(false);

        ParsedValue := CandidateValue;
        exit(true);
    end;

    local procedure TryParseRegion(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractSuffix(
            Fragment,
            ' область',
            ParsedValue)
        then
            exit(true);

        if TryExtractSuffix(
            Fragment,
            ' обл.',
            ParsedValue)
        then
            exit(true);

        if TryExtractSuffix(
            Fragment,
            ' обл',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseDistrict(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractSuffix(
            Fragment,
            ' район',
            ParsedValue)
        then
            exit(true);

        if TryExtractSuffix(
            Fragment,
            ' р-н',
            ParsedValue)
        then
            exit(true);

        if TryExtractSuffix(
            Fragment,
            ' р-н.',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseCity(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractPrefix(
            Fragment,
            'місто ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'м. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'м.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'село ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'с. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'с.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'селище міського типу ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'смт ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'смт. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'селище ',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseStreet(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractPrefix(
            Fragment,
            'вулиця ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'вул. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'вул.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'вул ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'проспект ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'просп. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'просп.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'провулок ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'пров. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'пров.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'бульвар ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'бул. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'бул.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'площа ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'пл. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'пл.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'набережна ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'шосе ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'узвіз ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'тупик ',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseBuilding(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractPrefix(
            Fragment,
            'будинок ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'буд. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'буд.',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'буд ',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseOffice(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractPrefix(
            Fragment,
            'офіс ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'оф. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'оф.',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryParseApartment(
        Fragment: Text;
        var ParsedValue: Text): Boolean
    begin
        if TryExtractPrefix(
            Fragment,
            'квартира ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'кв. ',
            ParsedValue)
        then
            exit(true);

        if TryExtractPrefix(
            Fragment,
            'кв.',
            ParsedValue)
        then
            exit(true);

        exit(false);
    end;

    local procedure TryExtractPrefix(
        SourceText: Text;
        PrefixText: Text;
        var ExtractedValue: Text): Boolean
    var
        CandidateText: Text;
    begin
        CandidateText := SourceText.Trim();

        if not StartsWithIgnoreCase(
            CandidateText,
            PrefixText)
        then
            exit(false);

        ExtractedValue :=
            CopyStr(
                CandidateText,
                StrLen(PrefixText) + 1);

        ExtractedValue := ExtractedValue.Trim();

        exit(true);
    end;

    local procedure TryExtractSuffix(
        SourceText: Text;
        SuffixText: Text;
        var ExtractedValue: Text): Boolean
    var
        CandidateText: Text;
    begin
        CandidateText := SourceText.Trim();

        if not EndsWithIgnoreCase(
            CandidateText,
            SuffixText)
        then
            exit(false);

        ExtractedValue :=
            CopyStr(
                CandidateText,
                1,
                StrLen(CandidateText) - StrLen(SuffixText));

        ExtractedValue := ExtractedValue.Trim();

        exit(true);
    end;

    local procedure StartsWithIgnoreCase(
        SourceText: Text;
        PrefixText: Text): Boolean
    begin
        if StrLen(SourceText) < StrLen(PrefixText) then
            exit(false);

        exit(
            LowerCase(
                CopyStr(
                    SourceText,
                    1,
                    StrLen(PrefixText))) =
            LowerCase(PrefixText));
    end;

    local procedure EndsWithIgnoreCase(
        SourceText: Text;
        SuffixText: Text): Boolean
    var
        StartPosition: Integer;
    begin
        if StrLen(SourceText) < StrLen(SuffixText) then
            exit(false);

        StartPosition :=
            StrLen(SourceText) -
            StrLen(SuffixText) +
            1;

        exit(
            LowerCase(
                CopyStr(
                    SourceText,
                    StartPosition,
                    StrLen(SuffixText))) =
            LowerCase(SuffixText));
    end;
    /*
        local procedure ContainsDigitsOnly(ValueText: Text): Boolean
        var
            Position: Integer;
            CharacterValue: Text[1];
        begin
            if ValueText = '' then
                exit(false);

            for Position := 1 to StrLen(ValueText) do begin
                CharacterValue :=
                    CopyStr(
                        ValueText,
                        Position,
                        1);

                if not (CharacterValue in
                    ['0', '1', '2', '3', '4',
                     '5', '6', '7', '8', '9'])
                then
                    exit(false);
            end;

            exit(true);
        end;
    */
    local procedure ContainsDigitsOnly(ValueText: Text): Boolean
    var
        Position: Integer;
        CharacterValue: Text[1];
    begin
        if ValueText = '' then
            exit(false);

        for Position := 1 to StrLen(ValueText) do begin
            CharacterValue :=
                CopyStr(
                    ValueText,
                    Position,
                    1);

            if StrPos(
                '0123456789',
                CharacterValue) = 0
            then
                exit(false);
        end;

        exit(true);
    end;

    var
        EmptyAddressMsg: Label
            'The source address is empty.';

        NoRecognizedFragmentsMsg: Label
            'No address fragments were recognized.';

        UnrecognizedFragmentMsg: Label
            'The address fragment "%1" was not recognized.';

        EmptyComponentMsg: Label
            'The value of address component "%1" is empty after parsing fragment "%2".';

        DuplicateComponentMsg: Label
            'Address component "%1" was recognized more than once. Existing value: "%2". New value: "%3".';

        CountryFieldNameLbl: Label
            'Country';

        PostCodeFieldNameLbl: Label
            'Post Code';

        RegionFieldNameLbl: Label
            'Region';

        DistrictFieldNameLbl: Label
            'District';

        CityFieldNameLbl: Label
            'City';

        StreetFieldNameLbl: Label
            'Street';

        BuildingFieldNameLbl: Label
            'Building';

        OfficeFieldNameLbl: Label
            'Office';

        ApartmentFieldNameLbl: Label
            'Apartment';
}