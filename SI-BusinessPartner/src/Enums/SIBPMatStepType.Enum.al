enum 54072 "SI BP Mat. Step Type"
{
    Extensible = false;
    Caption = 'Крок матеріалізації контрагента';

    value(10; Preflight)
    {
        Caption = 'Попередня перевірка';
    }

    value(20; "Create ERP Entity")
    {
        Caption = 'Створення ERP-сутності';
    }

    value(30; "Apply BC Template")
    {
        Caption = 'Застосування стандартного шаблону BC';
    }

    value(40; "Apply BP Data")
    {
        Caption = 'Перенесення канонічних даних контрагента';
    }

    value(50; "Create Bank Accounts")
    {
        Caption = 'Створення банківських рахунків';
    }

    value(60; "Ensure Company Contact")
    {
        Caption = 'Створення/визначення контакту компанії';
    }

    value(70; "Link Customer")
    {
        Caption = 'Зв''язування покупця';
    }

    value(80; "Link Vendor")
    {
        Caption = 'Зв''язування постачальника';
    }

    value(90; "Post Validate")
    {
        Caption = 'Фінальна перевірка';
    }

    value(100; "Finalize Projection")
    {
        Caption = 'Фіналізація ERP-проєкції';
    }
}