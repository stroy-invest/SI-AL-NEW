table 50419 "SI EDS Runtime Param"
{
    Caption = 'EDS Runtime Parameter';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }

        field(2; Code; Code[50])
        {
        }

        field(3; Value; Text[2048])
        {
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(CodeKey; Code)
        {
        }
    }

    procedure Add(ParameterCode: Code[50]; ParameterValue: Text)
    var
        LastEntryNo: Integer;
    begin
        Reset();
        if FindLast() then
            LastEntryNo := "Entry No.";

        Init();
        "Entry No." := LastEntryNo + 1;
        Code := ParameterCode;
        Value := CopyStr(ParameterValue, 1, MaxStrLen(Value));
        Insert();
    end;

    procedure TryGetValue(ParameterCode: Code[50]; var ParameterValue: Text): Boolean
    begin
        Reset();
        SetRange(Code, ParameterCode);
        if not FindFirst() then
            exit(false);

        ParameterValue := Value;
        exit(true);
    end;
}
