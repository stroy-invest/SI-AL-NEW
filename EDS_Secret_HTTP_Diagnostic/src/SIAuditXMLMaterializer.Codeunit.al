codeunit 70052 "SI Audit XML Materializer"
{
    // Lab-only XML mapping. No production BP or Address writes.
    procedure Process(var Entry: Record "SI Audit Entry"; var Log: Record "SI Audit Request Log")
    var
        Result: Record "SI Audit Registry Result";
        BP: Record "SI Audit BP";
        Addr: Record "SI Audit BP Address";
        Doc: XmlDocument;
        Root: XmlElement;
        Node: XmlNode;
        Company: XmlElement;
        InS: InStream;
        RegistryEDRPOU: Text;
        LegalName: Text;
        BPNo: Code[60];
        ExistingResult: Record "SI Audit Registry Result";
        SourceFullName: Text;
        NormalizedSource: Text;
        NormalizedRegistry: Text;
    begin
        if Log."HTTP Status Code" <> 200 then begin
            SetResult(Entry, Log, 'HTTP_ERROR', 'HTTP status is not 200', false);
            exit;
        end;
        // Prefer untouched HTTP bytes. The XML reader honors the XML declaration
        // (adm.tools uses windows-1251); never decode these bytes as UTF-8.
        Log.CalcFields("Raw HTTP Bytes", "Raw Response");
        if Log."Raw HTTP Bytes".HasValue() then begin
            Log."Raw HTTP Bytes".CreateInStream(InS);
            if not XmlDocument.ReadFrom(InS, Doc) then begin
                SetResult(Entry, Log, 'INVALID_XML', 'XML parser rejected original HTTP bytes (check encoding declaration)', false);
                exit;
            end;
        end else begin
            if not Log."Raw Response".HasValue() then begin
                SetResult(Entry, Log, 'NO_DATA', 'Порожнє тіло відповіді', false);
                exit;
            end;
            // Legacy EDS buffer is stored as UTF-8 text. It may already contain
            // mojibake: do not silently treat it as authoritative registry data.
            SetResult(Entry, Log, 'RAW_REQUIRED',
                'Немає оригінальних HTTP-байтів. Виконайте RAW GET для коректного XML-декодування.', false);
            exit;
        end;
        Doc.GetRoot(Root);
        if LowerCase(Root.Name()) = 'error' then begin
            SetResult(Entry, Log, 'PROVIDER_ERROR', CopyStr(Root.InnerText(), 1, 500), false);
            exit;
        end;
        if Root.SelectSingleNode('error', Node) then begin
            SetResult(Entry, Log, 'PROVIDER_ERROR', CopyStr(Node.AsXmlElement().InnerText(), 1, 500), false);
            exit;
        end;
        if not Root.SelectSingleNode('company', Node) then begin
            SetResult(Entry, Log, 'NO_DATA', 'В XML відсутній вузол company', false);
            exit;
        end;
        Company := Node.AsXmlElement();
        RegistryEDRPOU := GetAttr(Company, 'egrpou');
        if RegistryEDRPOU <> Entry.EDRPOU then begin
            SetResult(Entry, Log, 'ID_MISMATCH',
                CopyStr(StrSubstNo('Запитано %1; повернуто %2', Entry.EDRPOU, RegistryEDRPOU), 1, 500), false);
            exit;
        end;
        LegalName := GetAttr(Company, 'name');
        if LegalName = '' then begin
            SetResult(Entry, Log, 'NO_DATA', 'Відсутня юридична назва company.name', false);
            exit;
        end;

        // One materialized result per source entry. Re-running updates, never duplicates.
        if ExistingResult.Get(Log."Entry No.") then
            ExistingResult.Delete();
        Result.Init();
        Result."Entry No." := Log."Entry No.";
        Result."Provider Code" := Log."EDS Provider Code";
        Result."Country/Region Code" := 'UA';
        Result."Registration No." := CopyStr(RegistryEDRPOU, 1, MaxStrLen(Result."Registration No."));
        Result."Identifier Value" := Result."Registration No.";
        Result."Tax Registration No." := CopyStr(GetAttr(Company, 'inn'), 1, MaxStrLen(Result."Tax Registration No."));
        Result."Legal Name" := CopyStr(LegalName, 1, MaxStrLen(Result."Legal Name"));
        Result."Registry Short Name" := CopyStr(GetAttr(Company, 'name_short'), 1, MaxStrLen(Result."Registry Short Name"));
        Result.Address := CopyStr(GetAttr(Company, 'address'), 1, MaxStrLen(Result.Address));
        Result.Director := CopyStr(GetAttr(Company, 'director'), 1, MaxStrLen(Result.Director));
        Result."Director Genitive" := CopyStr(GetAttr(Company, 'director_gen'), 1, MaxStrLen(Result."Director Genitive"));
        Result."KVED No." := CopyStr(GetAttr(Company, 'kved_number'), 1, MaxStrLen(Result."KVED No."));
        Result."KVED Description" := CopyStr(GetAttr(Company, 'kved'), 1, MaxStrLen(Result."KVED Description"));
        Result."Registration Date" := CopyStr(GetAttr(Company, 'date_from'), 1, MaxStrLen(Result."Registration Date"));
        Result."Tax Registration Date" := CopyStr(GetAttr(Company, 'inn_date'), 1, MaxStrLen(Result."Tax Registration Date"));
        Result."Registry Last Update" := CopyStr(GetAttr(Company, 'last_update'), 1, MaxStrLen(Result."Registry Last Update"));
        Result."Identity Provided" := true;
        Result."Names Provided" := true;
        Result."Address Provided" := GetAttr(Company, 'address') <> '';
        Result."Manager Provided" := GetAttr(Company, 'director') <> '';
        Result."Main Activity Provided" := GetAttr(Company, 'kved_number') <> '';
        Result.Insert();

        // Synthetic key isolates the lab and avoids collision between batches/entries.
        BPNo := CopyStr(StrSubstNo('%1-%2', Entry."Batch No.", Entry."Entry No."), 1, MaxStrLen(BPNo));
        if not BP.Get(BPNo) then begin
            BP.Init();
            BP."No." := BPNo;
            BP.Insert();
        end;
        BP.Name := CopyStr(LegalName, 1, MaxStrLen(BP.Name));
        BP."Search Name" := CopyStr(UpperCase(LegalName), 1, MaxStrLen(BP."Search Name"));
        BP."Country/Region Code" := 'UA';
        BP."Registration No." := Result."Registration No.";
        BP."Tax Registration No." := Result."Tax Registration No.";
        BP."Registry Legal Name" := Result."Legal Name";
        BP."Registry Short Name" := Result."Registry Short Name";
        BP."Main KVED No." := Result."KVED No.";
        BP."Main KVED Description" := Result."KVED Description";
        BP."Manager Name" := Result.Director;
        BP."Registry Provider Code" := Log."EDS Provider Code";
        // No status from adm.tools: do not infer legal activity or termination.
        BP.Modify();

        Addr.Reset();
        Addr.SetRange("Business Partner No.", BPNo);
        Addr.SetRange("Verification Source", 'ADM-TOOLS');
        if not Addr.FindFirst() then begin
            Addr.Init();
            Addr."Business Partner No." := BPNo;
            Addr."Verification Source" := 'ADM-TOOLS';
            Addr.Insert();
        end;
        Addr."Country/Region Code" := 'UA';
        Addr."Raw Address" := Result.Address;
        Addr."Verification Date/Time" := Log."Completed At";
        Addr.Verified := false; // raw source != manually verified address
        Addr.Modify();
        Entry."Audit BP No." := BPNo;
        Entry.Modify();

        // The source model separates legal form and company name.
        // Preserve source values; compare only derived normalized values.
        SourceFullName := Entry."Source Legal Form".Trim();
        if Entry."Source Name".Trim() <> '' then begin
            if SourceFullName <> '' then
                SourceFullName += ' ';
            SourceFullName += Entry."Source Name".Trim();
        end;
        NormalizedSource := NormalizeName(SourceFullName);
        NormalizedRegistry := NormalizeName(LegalName);
        Entry."Full Name 1C" := CopyStr(SourceFullName, 1, MaxStrLen(Entry."Full Name 1C"));
        Entry."Registry Full Name" := CopyStr(LegalName, 1, MaxStrLen(Entry."Registry Full Name"));
        Entry."Normalized Name 1C" := CopyStr(NormalizedSource, 1, MaxStrLen(Entry."Normalized Name 1C"));
        Entry."Normalized Registry Name" := CopyStr(NormalizedRegistry, 1, MaxStrLen(Entry."Normalized Registry Name"));
        Entry.Modify();

        if (NormalizedSource <> '') and (NormalizedSource = NormalizedRegistry) then
            SetResult(Entry, Log, 'MATCH', 'Повна назва 1С збігається з юридичною назвою реєстру після нормалізації', true)
        else
            SetResult(Entry, Log, 'NAME_MISMATCH', 'Нормалізовані повні назви 1С та реєстру відрізняються; потрібен перегляд', true);
    end;

    local procedure GetAttr(E: XmlElement; N: Text): Text
    var A: XmlAttribute;
    begin
        if E.Attributes().Get(N, A) then exit(A.Value());
        exit('');
    end;

    local procedure NormalizeName(Value: Text): Text
    var
        I: Integer;
        Ch: Text[1];
        Clean: Text;
        PrevSpace: Boolean;
    begin
        Value := UpperCase(Value);
        // Discard decorative quote characters, preserve significant letters/digits.
        Value := Value.Replace('«', '').Replace('»', '').Replace('"', '');
        Value := Value.Replace('''', '').Replace('’', '').Replace('‘', '');
        Value := Value.Replace('“', '').Replace('”', '').Replace('„', '').Replace('`', '');
        Value := Value.Replace('＂', '').Replace('′', '').Replace('″', '');
        Value := Value.Replace('(', ' ').Replace(')', ' ');
        Value := Value.Replace('-', ' ').Replace('–', ' ').Replace('—', ' ');
        Value := Value.Replace('.', ' ').Replace(',', ' ');
        PrevSpace := true;
        for I := 1 to StrLen(Value) do begin
            Ch := CopyStr(Value, I, 1);
            if (Ch = ' ') or (Ch = ' ') or (Ch = '　') then begin
                if not PrevSpace then begin
                    Clean += ' ';
                    PrevSpace := true;
                end;
            end else begin
                Clean += Ch;
                PrevSpace := false;
            end;
        end;
        exit(Clean.Trim());
    end;

    local procedure SetResult(var Entry: Record "SI Audit Entry"; var Log: Record "SI Audit Request Log"; ResultCode: Code[30]; Details: Text; Parsed: Boolean)
    begin
        Log."Verification Result" := ResultCode;
        Log."Response Message" := CopyStr(Details, 1, MaxStrLen(Log."Response Message"));
        Log.Modify();
        Entry."Result Code" := ResultCode;
        Entry."Result Details" := CopyStr(Details, 1, MaxStrLen(Entry."Result Details"));
        if ResultCode = 'MATCH' then
            Entry."Processing Status" := Entry."Processing Status"::Success
        else
            if Parsed then
                Entry."Processing Status" := Entry."Processing Status"::Review
            else
                Entry."Processing Status" := Entry."Processing Status"::Failed;
        Entry.Modify();
    end;
}
