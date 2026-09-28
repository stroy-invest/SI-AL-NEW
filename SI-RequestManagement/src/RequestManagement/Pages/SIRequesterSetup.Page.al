page 52019 "SI Requester Setup"
{
    PageType = List;

    SourceTable = "SI Requester Setup";

    // Дозволяємо використовувати сторінку в усіх application areas.
    ApplicationArea = All;

    // Сторінка буде доступна через пошук BC.
    UsageCategory = Administration;

    // Назва сторінки в інтерфейсі.
    Caption = 'Налаштування заявників';

    layout
    {
        area(Content)
        {
            repeater(Requesters)
            {
                // BC User, під яким користувач входить у систему.
                // Саме це значення потім порівнюємо з UserId().
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Користувач Business Central, який створює заявки.';
                }

                // Співробітник зі стандартного довідника Employees.
                // Це дозволяє знати не лише технічний User ID,
                // а конкретну фізичну особу: ПІБ, табельний номер тощо.
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Співробітник, пов’язаний із цим користувачем.';
                }

                // Об’єкт будівництва, за який відповідає цей заявник.
                // Саме цей об’єкт потім автоматично підставлятиметься в заявку.
                field("Construction Object No."; Rec."Construction Object No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Об’єкт будівництва, закріплений за заявником.';
                }

                // Ознака активності.
                // Дає змогу тимчасово вимкнути прив’язку без видалення запису.
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи активна ця прив’язка користувача до співробітника та об’єкта.';
                }
            }
        }
    }
}
