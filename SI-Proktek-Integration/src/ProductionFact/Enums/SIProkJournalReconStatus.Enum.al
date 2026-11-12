enum 57123 "SI Prok Journal Recon Status"
{
    Extensible = false;
    value(0; NotChecked) { Caption = 'Не перевірено'; }
    value(1; Ready) { Caption = 'Готовий до проведення'; }
    value(2; Mismatch) { Caption = 'Змінений рядок'; }
    value(3; Missing) { Caption = 'Рядок відсутній — розслідування'; }
    value(4; Legacy) { Caption = 'Немає контрольного знімка'; }
}
