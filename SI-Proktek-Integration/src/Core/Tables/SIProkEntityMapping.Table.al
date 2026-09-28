table 57010 "SI Prok Entity Mapping"
{
    Caption = 'Відповідність сутностей Proktek';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Prok Entity Mappings";
    LookupPageId = "SI Prok Entity Mappings";

    fields
    {
        field(1; "Connection Code"; Code[50])
        {
            Caption = 'Підключення';
            TableRelation = "SI Prok Connection".Code;
        }
        field(2; "Entity Type"; Enum "SI Prok Entity Type")
        {
            Caption = 'Тип сутності';
        }
        field(3; "BC SystemId"; Guid)
        {
            Caption = 'BC SystemId';
        }
        field(4; "BC No."; Code[20])
        {
            Caption = 'Номер у BC';
        }
        field(10; "Proktek UUID"; Guid)
        {
            Caption = 'UUID Proktek';
        }
        field(11; "Proktek Code"; Text[100])
        {
            Caption = 'Код Proktek';
        }
        field(12; "Proktek Internal Code"; BigInteger)
        {
            Caption = 'Внутрішній ID Proktek';
        }
        field(20; "Last Sync At"; DateTime)
        {
            Caption = 'Остання синхронізація';
        }
        field(21; "Last Response Message"; Text[2048])
        {
            Caption = 'Остання відповідь Proktek';
        }
    }

    keys
    {
        key(PK; "Connection Code", "Entity Type", "BC SystemId")
        {
            Clustered = true;
        }

        key(ProktekIdentity; "Connection Code", "Entity Type", "Proktek UUID")
        {
        }

        key(BCNo; "Connection Code", "Entity Type", "BC No.")
        {
        }
    }
}
