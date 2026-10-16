namespace STROYINVEST.ConcreteRecipeEngine;

using System.Security.AccessControl;

codeunit 62212 "SI Recipe Admin Edit Access"
{
    procedure IsSuper(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'SUPER');
        exit(not AccessControl.IsEmpty());
    end;

    procedure RequireSuper()
    begin
        if not IsSuper() then
            Error(SuperRequiredErr);
    end;

    var
        SuperRequiredErr: Label 'Адміністративне коригування рецептури доступне лише користувачам із набором дозволів SUPER.';
}
