tableextension 59151 "SI WB Location Ext" extends Location
{
    fields
    {
        field(59150; "SI WB Default Receipt"; Boolean)
        {
            Caption = 'Використовується для прибуткування за замовчуванням';
            DataClassification = CustomerContent;
            ToolTip = 'Дозволяє використовувати склад як резервний склад прибуткування, коли Posting Template не визначає склад. Конкретні категорії, товари та варіанти задаються у правилах нижче.';
        }
    }
}
