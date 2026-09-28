codeunit 59053 "SI WB Job Failure Test"
{
    trigger OnRun()
    begin
        Error(
            'SI Weighbridge: контрольований тест помилки Job Queue. ' +
            'Цю помилку створено навмисно для перевірки системи сповіщень.');
    end;
}