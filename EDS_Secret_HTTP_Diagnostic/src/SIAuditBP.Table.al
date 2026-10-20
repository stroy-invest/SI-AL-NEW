// Registry Audit Step 1. Field IDs/types derived from src/Tables/SIBusinessPartner.Table.al.
// No source triggers, FlowFields, or relations to production BP are executed.
table 70000 "SI Audit BP"
{
    Caption = 'SI Audit BP';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "No."; Code[60]) { Caption = 'Код';  }
        field(2; Name; Text[100]) { Caption = 'Назва контрагента';  }
        field(3; "Search Name"; Code[100]) { Caption = 'Назва для пошуку';  }
        field(4; Status; Enum "SI BP Status") { Caption = 'Статус';  }
        field(16; "Entity Type"; Enum "SI BP Entity Type") { Caption = 'Тип контрагента';  }
        field(5; "Country/Region Code"; Code[10]) { Caption = 'Код країни/регіону';  }
        field(6; "Registration No."; Text[50]) { Caption = 'Реєстраційний номер';  }
        field(7; "Tax Registration No."; Text[50]) { Caption = 'Податковий реєстраційний номер';  }
        field(8; "Legal Form Code"; Code[20]) { Caption = 'Нормалізована юридична форма';  }
        field(9; "Local Legal Form Code"; Code[20]) { Caption = 'Офіційна юридична форма';  }
        field(10; "Is Customer"; Boolean) { Caption = 'Клієнт';  }
        field(11; "Is Vendor"; Boolean) { Caption = 'Постачальник';  }
        field(12; "Customer No."; Code[20]) { Caption = 'Код покупця';  }
        field(13; "Vendor No."; Code[20]) { Caption = 'Код постачальника';  }
        field(14; "Full Legal Form"; Text[150]) { Caption = 'Повна юридична форма';  }
        field(15; "Short Name BK"; Text[150]) { Caption = 'Робоча назва';  }
        field(17; "Currency Code"; Code[10]) { Caption = 'Валюта контрагента';  }
        field(18; "Registry Legal Name"; Text[500]) { Caption = 'Юридична назва з реєстру';  }
        field(19; "Registry Short Name"; Text[250]) { Caption = 'Скорочена назва з реєстру';  }
        field(20; "Registry Status"; Text[100]) { Caption = 'Статус у реєстрі';  }
        field(21; "Main KVED No."; Text[30]) { Caption = 'Код основного КВЕД';  }
        field(22; "Main KVED Description"; Text[500]) { Caption = 'Основний КВЕД';  }
        field(23; "Manager Name"; Text[250]) { Caption = 'Керівник';  }
        field(24; "Manager Role"; Text[100]) { Caption = 'Посада/роль керівника';  }
        field(25; "Manager Appointed At"; DateTime) { Caption = 'Дата призначення керівника';  }
        field(26; "Manager Authority"; Text[500]) { Caption = 'Відомості про повноваження';  }
        field(27; "Registry Data Actual At"; DateTime) { Caption = 'Дані реєстру актуальні на';  }
        field(28; "Registry Provider Code"; Code[50]) { Caption = 'Джерело реєстрових даних';  }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
