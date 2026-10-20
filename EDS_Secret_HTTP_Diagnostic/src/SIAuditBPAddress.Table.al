// Registry Audit Step 1. Field IDs/types derived from src/Tables/SIBPAddress.Table.al.
// No source triggers, FlowFields, or relations to production BP are executed.
table 70001 "SI Audit BP Address"
{
    Caption = 'SI Audit BP Address';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Номер запису'; AutoIncrement = true; }
        field(2; "Business Partner No."; Code[60]) { Caption = 'Код контрагента';  }
        field(3; "Address Type"; Enum "SI BP Address Type") { Caption = 'Тип адреси';  }
        field(4; "Country/Region Code"; Code[10]) { Caption = 'Код країни/регіону';  }
        field(5; "Region/State"; Text[100]) { Caption = 'Область/регіон';  }
        field(6; District; Text[100]) { Caption = 'Район';  }
        field(7; City; Text[100]) { Caption = 'Місто';  }
        field(8; "Post Code"; Code[20]) { Caption = 'Поштовий індекс';  }
        field(9; Street; Text[150]) { Caption = 'Вулиця';  }
        field(10; "Building No."; Text[30]) { Caption = 'Номер будинку';  }
        field(11; "Office/Apartment"; Text[30]) { Caption = 'Офіс/квартира';  }
        field(12; "Address Details"; Text[250]) { Caption = 'Деталі адреси';  }
        field(13; "Raw Address"; Text[500]) { Caption = 'Адреса з джерела';  }
        field(14; "Valid From"; Date) { Caption = 'Діє з';  }
        field(15; "Valid To"; Date) { Caption = 'Діє до';  }
        field(16; "Is Primary"; Boolean) { Caption = 'Основний';  }
        field(17; Verified; Boolean) { Caption = 'Перевірено';  }
        field(18; "Verification Source"; Code[30]) { Caption = 'Джерело перевірки';  }
        field(19; "Verification Date/Time"; DateTime) { Caption = 'Дата й час перевірки';  }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
