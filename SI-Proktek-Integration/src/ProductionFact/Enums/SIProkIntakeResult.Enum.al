enum 57102 "SI Prok Intake Result"
{
    Extensible = false;
    value(0; NotEvaluated) { Caption = 'Не оцінено'; }
    value(1; Imported) { Caption = 'Новий факт'; }
    value(2; Existing) { Caption = 'Існуючий незмінений'; }
    value(3; Conflict) { Caption = 'Конфлікт'; }
    value(4; Error) { Caption = 'Помилка обробки'; }
}
