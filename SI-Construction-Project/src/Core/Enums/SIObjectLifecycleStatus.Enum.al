enum 60003 "SI Object Lifecycle Status"
{
    Extensible = false;
    Caption = 'Стан життєвого циклу SI';

    value(0; Active) { Caption = 'Активний'; }
    value(1; Freezed) { Caption = 'Заморожений'; }
    value(2; Annulated) { Caption = 'Анульований'; }
}
