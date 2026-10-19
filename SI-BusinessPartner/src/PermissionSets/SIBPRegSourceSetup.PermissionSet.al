permissionset 54090 "SI BP REG SOURCE"
{
    Assignable = true;
    Caption = 'Налаштування джерел реєстру BP';

    Permissions =
        tabledata "SI BP Registry Source" = RIMD,
        table "SI BP Registry Source" = X,
        page "SI BP Registry Sources" = X;
}
